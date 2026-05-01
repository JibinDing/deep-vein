#!/usr/bin/env python3
"""张雪峰语音助手 - 低延迟流水线版

录音(VAD自动停) → Whisper medium → DeepSeek 流式 → 逐句TTS → 边合成边播放
"""

import io
import os
import queue
import tempfile
import threading
from pathlib import Path

import httpx
import numpy as np
import sounddevice as sd
import soundfile as sf
from faster_whisper import WhisperModel
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

# ── 配置 ──────────────────────────────────────────────────────────────────────

SAMPLE_RATE = 16000
FISH_VOICE_ID = "01f6deb6f58546598dbf77cc0b40304d"
SKILL_FILE = Path(__file__).parent.parent / ".agents/skills/zhangxuefeng-perspective/SKILL.md"

# 静音检测参数
VAD_SILENCE_SEC = 1.2    # 静音超过这么多秒就停止录音
VAD_THRESHOLD   = 0.015  # 音量低于这个值视为静音
VAD_CHUNK       = 512    # 每次读取的帧数

# 句子分割符（凑够一句就送 TTS）
SENTENCE_ENDS = set("。！？…\n")

# ── 初始化 ────────────────────────────────────────────────────────────────────

print("加载 Whisper medium 模型...", flush=True)
try:
    whisper = WhisperModel("medium", device="cuda", compute_type="float16")
    print("Whisper: GPU ✓")
except Exception:
    whisper = WhisperModel("medium", device="cpu", compute_type="int8")
    print("Whisper: CPU ✓")

deepseek = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url="https://api.deepseek.com",
)

system_prompt = SKILL_FILE.read_text(encoding="utf-8")
conversation: list[dict] = []

# ── 录音（VAD 自动停止）────────────────────────────────────────────────────────

def record() -> np.ndarray:
    """开口说话自动开始，停顿 1.2 秒自动结束。"""
    print("  🎙  说吧（停顿后自动停止）", flush=True)

    frames: list[np.ndarray] = []
    silent_chunks = 0
    started = False
    max_silent = int(VAD_SILENCE_SEC * SAMPLE_RATE / VAD_CHUNK)

    with sd.InputStream(samplerate=SAMPLE_RATE, channels=1,
                        dtype="float32", blocksize=VAD_CHUNK) as stream:
        while True:
            data, _ = stream.read(VAD_CHUNK)
            rms = float(np.sqrt(np.mean(data ** 2)))

            if rms > VAD_THRESHOLD:
                started = True
                silent_chunks = 0
                frames.append(data.copy())
            elif started:
                frames.append(data.copy())
                silent_chunks += 1
                if silent_chunks >= max_silent:
                    break
            # 未开口前忽略静音，避免立刻退出

    return np.concatenate(frames) if frames else np.zeros(SAMPLE_RATE, dtype="float32")


# ── STT ───────────────────────────────────────────────────────────────────────

def transcribe(audio: np.ndarray) -> str:
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        sf.write(f.name, audio, SAMPLE_RATE)
        segments, _ = whisper.transcribe(
            f.name,
            language="zh",
            beam_size=1,       # 速度优先
            vad_filter=True,   # 过滤静音片段
        )
        return "".join(seg.text for seg in segments).strip()


# ── TTS ───────────────────────────────────────────────────────────────────────

def synthesize(text: str) -> bytes:
    with httpx.Client(timeout=30) as client:
        resp = client.post(
            "https://api.fish.audio/v1/tts",
            headers={
                "Authorization": f"Bearer {os.getenv('FISH_API_KEY')}",
                "Content-Type": "application/json",
            },
            json={
                "text": text,
                "reference_id": FISH_VOICE_ID,
                "format": "wav",
                "latency": "optimized",   # Fish Audio 低延迟模式
            },
        )
        resp.raise_for_status()
        return resp.content


def play(audio_bytes: bytes):
    data, sr = sf.read(io.BytesIO(audio_bytes), dtype="float32")
    sd.play(data, sr)
    sd.wait()


# ── LLM + 流水线 ──────────────────────────────────────────────────────────────

def chat_streaming(user_text: str) -> str:
    """
    DeepSeek 流式输出 → 逐句送 TTS → TTS 和播放并行。

    TTS 线程和播放线程通过两个队列解耦：
      text_q:  LLM 线程 → TTS 线程（句子文本）
      audio_q: TTS 线程 → 播放线程（wav 字节）
    """
    conversation.append({"role": "user", "content": user_text})

    text_q: queue.Queue[str | None]  = queue.Queue()
    audio_q: queue.Queue[bytes | None] = queue.Queue()

    def tts_worker():
        """收到完整句子就合成，放进 audio_q。"""
        buf = ""
        while True:
            chunk = text_q.get()
            if chunk is None:              # 上游结束
                if buf.strip():
                    audio_q.put(synthesize(buf.strip()))
                audio_q.put(None)
                break
            buf += chunk
            # 遇到句子边界就切出去合成
            while True:
                cut = -1
                for i, ch in enumerate(buf):
                    if ch in SENTENCE_ENDS:
                        cut = i
                        break
                if cut == -1:
                    break
                sentence = buf[: cut + 1].strip()
                buf = buf[cut + 1 :]
                if sentence:
                    audio_q.put(synthesize(sentence))

    def play_worker():
        """拿到音频就播放，串行保证顺序。"""
        while True:
            audio = audio_q.get()
            if audio is None:
                break
            play(audio)

    tts_thread  = threading.Thread(target=tts_worker,  daemon=True)
    play_thread = threading.Thread(target=play_worker, daemon=True)
    tts_thread.start()
    play_thread.start()

    # 主线程：流式拿 LLM 输出，打印并送给 TTS 线程
    print("\n张雪峰: ", end="", flush=True)
    full_parts: list[str] = []

    stream = deepseek.chat.completions.create(
        model="deepseek-chat",
        max_tokens=1024,
        messages=[{"role": "system", "content": system_prompt}, *conversation],
        stream=True,
    )
    for chunk in stream:
        delta = chunk.choices[0].delta.content or ""
        if delta:
            print(delta, end="", flush=True)
            full_parts.append(delta)
            text_q.put(delta)

    text_q.put(None)   # 通知 TTS 线程结束
    tts_thread.join()
    play_thread.join()
    print()            # 换行

    full_text = "".join(full_parts)
    conversation.append({"role": "assistant", "content": full_text})
    return full_text


# ── 主循环 ────────────────────────────────────────────────────────────────────

def main():
    print("\n" + "=" * 40)
    print("     张雪峰语音助手  (低延迟版)")
    print("=" * 40)
    print("  直接说话  语音输入（自动VAD）")
    print("  t        文字输入（调试用）")
    print("  r        清空对话记忆")
    print("  q        退出")
    print("=" * 40 + "\n")

    while True:
        try:
            choice = input(">>> ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            print("\n拜了。")
            break

        if choice == "q":
            print("拜了。")
            break

        elif choice == "r":
            conversation.clear()
            print("记忆已清空。\n")
            continue

        elif choice == "t":
            user_text = input("你: ").strip()

        else:
            # 默认走语音（输入任意内容或直接回车都触发录音）
            try:
                audio = record()
            except Exception as e:
                print(f"录音失败: {e}\n")
                continue
            print("  识别中...", end=" ", flush=True)
            user_text = transcribe(audio)
            if not user_text:
                print("没听清，再来一次\n")
                continue
            print(f"你说: {user_text}")

        if not user_text:
            continue

        try:
            chat_streaming(user_text)
        except Exception as e:
            print(f"出错: {e}\n")


if __name__ == "__main__":
    main()
