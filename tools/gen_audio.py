#!/usr/bin/env python3
"""
Tạo toàn bộ âm thanh của game (không tốn lượt AI, không dùng file có bản quyền):

    python3 tools/gen_audio.py              # tạo hết
    python3 tools/gen_audio.py sfx          # chỉ hiệu ứng
    python3 tools/gen_audio.py voice        # chỉ giọng (đai biến thân, tiếng hô)
    python3 tools/gen_audio.py music [id..] # chỉ nhạc (vd: music kuuga boss)

  audio/sfx/<tên>.wav      hiệu ứng 8-bit tổng hợp bằng code (bảng SFX bên dưới), kể cả tiếng biến thân riêng từng
                           Rider "henshin_<rider>" (Faiz bấm 5-5-5 Enter, Hibiki gõ âm thoa Onsa...)
  audio/voice/<tên>.wav    giọng đai / tiếng hô: đọc câu ngắn bằng giọng máy macOS (`say`), rồi ffmpeg hạ giọng, nén bit,
                           thêm vang cho giống đai biến thân. Câu lấy từ hằng VOICE trong scripts/data/worlds/wNN_*.gd:
                             <rider>_henshin, <rider>_<form> (đổi form), <rider>_final; hero_henshin (tiếng hô của Sora)
  audio/music/<tên>.mp3    nhạc nền chiptune 4 kênh (lead vuông, hoà âm, bass tam giác, trống nhiễu), mỗi bài một
                           vòng 16 nhịp lặp liền: map, boss, clear (đoạn ngắn không lặp), stage_<id thế giới> (giai điệu
                           sinh từ id thế giới nên vẽ lại vẫn y hệt).

Cần: macOS `say`, ffmpeg (libmp3lame). Python thuần, không cần numpy.
"""
import math
import os
import random
import re
import struct
import subprocess
import sys
import tempfile
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "audio")
SR = 22050


# --- Tổng hợp cơ bản -----------------------------------------------------------

def write_wav(path, samples, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = min(1.0, 0.92 / peak)
    data = struct.pack("<%dh" % len(samples), *(int(max(-1.0, min(1.0, s * gain)) * 32767) for s in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data)


class Noise:
    def __init__(self, seed=1):
        self.r = random.Random(seed)

    def __call__(self):
        return self.r.uniform(-1.0, 1.0)


def square(ph, duty=0.5):
    return 1.0 if (ph % 1.0) < duty else -1.0


def tri(ph):
    p = ph % 1.0
    return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p


def saw(ph):
    return 2.0 * (ph % 1.0) - 1.0


def tone(dur, f0, f1=None, wave_fn=square, vol=1.0, attack=0.005, decay=None, curve=1.0, duty=0.5, vib=0.0,
         vib_rate=6.0, trem=0.0, trem_rate=12.0):
    """Một nốt / tiếng quét: tần số f0 → f1 (theo hàm mũ), bao âm attack rồi tắt dần (curve > 1 tắt nhanh hơn)."""
    n = int(dur * SR)
    f1 = f0 if f1 is None else f1
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / n
        f = f0 * (f1 / f0) ** t if f0 > 0 and f1 > 0 else f0 + (f1 - f0) * t
        if vib:
            f *= 1.0 + vib * math.sin(2 * math.pi * vib_rate * i / SR)
        ph += f / SR
        if wave_fn is square:
            v = square(ph, duty)
        elif wave_fn is math.sin:
            v = math.sin(2 * math.pi * ph)
        else:
            v = wave_fn(ph)
        env = min(1.0, i / max(1, attack * SR)) * ((1.0 - t) ** curve if decay is None else math.exp(-i / (decay * SR)))
        if trem:
            env *= 1.0 - trem * (0.5 + 0.5 * math.sin(2 * math.pi * trem_rate * i / SR))
        out[i] = v * env * vol
    return out


def noise(dur, vol=1.0, curve=1.5, lowpass=1.0, seed=3, attack=0.002, highpass=0.0):
    """Tiếng nhiễu: lowpass 0..1 (1 = không lọc), highpass 0..1 (bỏ phần trầm)."""
    n = int(dur * SR)
    src = Noise(seed)
    out = [0.0] * n
    lp = 0.0
    hp_prev = 0.0
    for i in range(n):
        t = i / n
        x = src()
        lp += lowpass * (x - lp)
        v = lp
        if highpass:
            hp = v - hp_prev * (1.0 - highpass)
            hp_prev = v
            v = hp
        env = min(1.0, i / max(1, attack * SR)) * (1.0 - t) ** curve
        out[i] = v * env * vol
    return out


def mix(*parts, offsets=None):
    offsets = offsets or [0.0] * len(parts)
    n = max(int(o * SR) + len(p) for p, o in zip(parts, offsets))
    out = [0.0] * n
    for p, o in zip(parts, offsets):
        s = int(o * SR)
        for i, v in enumerate(p):
            out[s + i] += v
    return out


def seq(*parts, gap=0.0):
    out = []
    for p in parts:
        out += p + [0.0] * int(gap * SR)
    return out


def echo(samples, delay=0.12, fb=0.35, times=3):
    d = int(delay * SR)
    out = samples + [0.0] * d * times
    for k in range(1, times + 1):
        g = fb ** k
        for i, v in enumerate(samples):
            out[i + d * k] += v * g
    return out


def crush(samples, step=4):
    """Giảm tần số mẫu kiểu 8-bit (giữ mẫu mỗi `step` mẫu)."""
    return [samples[i - i % step] for i in range(len(samples))]


def note_hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def arp(notes, step=0.06, vol=0.6, duty=0.25, last=0.25):
    parts = []
    for i, m in enumerate(notes):
        d = last if i == len(notes) - 1 else step
        parts.append(tone(d, note_hz(m), wave_fn=square, duty=duty, vol=vol, curve=1.2))
    return seq(*parts)


def dtmf(key, dur=0.12):
    low = {"1": 697, "2": 697, "3": 697, "4": 770, "5": 770, "6": 770, "7": 852, "8": 852, "9": 852, "*": 941,
           "0": 941, "#": 941}[key]
    high = {"1": 1209, "4": 1209, "7": 1209, "*": 1209, "2": 1336, "5": 1336, "8": 1336, "0": 1336, "3": 1477,
            "6": 1477, "9": 1477, "#": 1477}[key]
    return mix(tone(dur, low, wave_fn=math.sin, vol=0.45, curve=0.3), tone(dur, high, wave_fn=math.sin, vol=0.45, curve=0.3))


def bell(dur, f, vol=0.6):
    return mix(tone(dur, f, wave_fn=math.sin, vol=vol, decay=dur / 4),
               tone(dur, f * 2.76, wave_fn=math.sin, vol=vol * 0.35, decay=dur / 8),
               tone(dur, f * 5.4, wave_fn=math.sin, vol=vol * 0.15, decay=dur / 14))


# --- Hiệu ứng -------------------------------------------------------------------

def boom(dur=0.6, vol=1.0):
    return mix(tone(dur, 110, 30, wave_fn=math.sin, vol=vol, curve=1.4), noise(dur, vol=0.8 * vol, lowpass=0.18, curve=1.6))


SFX = {
    # Đòn của người chơi
    "punch": lambda: mix(noise(0.07, 0.6, lowpass=0.35), tone(0.08, 190, 70, wave_fn=math.sin, vol=0.9)),
    "kick": lambda: mix(noise(0.1, 0.7, lowpass=0.3), tone(0.13, 150, 45, wave_fn=math.sin, vol=1.0)),
    "slash": lambda: mix(noise(0.13, 0.8, lowpass=0.9, highpass=0.4, curve=1.2), tone(0.1, 1800, 700, vol=0.12, duty=0.15)),
    "slash_heavy": lambda: mix(noise(0.2, 0.9, lowpass=0.7, highpass=0.3, curve=1.0), tone(0.18, 900, 220, vol=0.2, duty=0.3)),
    "swing_wind": lambda: noise(0.22, 0.6, lowpass=0.25, curve=0.8, attack=0.06),
    "hit": lambda: mix(tone(0.09, 320, 110, vol=0.5, duty=0.4), noise(0.06, 0.6, lowpass=0.5)),
    "hit_heavy": lambda: mix(tone(0.16, 220, 60, vol=0.6, duty=0.5), noise(0.14, 0.9, lowpass=0.35), tone(0.14, 90, 40, wave_fn=math.sin, vol=0.8)),
    # Chém đạn: tiếng kim loại "keng" ngắn; phản đạn: keng + vang chuông cao đi lên
    "parry": lambda: mix(tone(0.1, 2600, 2200, vol=0.3, duty=0.25, curve=2), bell(0.18, 1900, 0.25), noise(0.04, 0.5, lowpass=0.9, highpass=0.5)),
    "parry_perfect": lambda: mix(tone(0.12, 2800, 2400, vol=0.35, duty=0.25, curve=2), bell(0.45, 2093, 0.3), bell(0.45, 3136, 0.2),
                                 noise(0.05, 0.6, lowpass=0.9, highpass=0.5), offsets=[0, 0, 0.06, 0]),
    "hit_guard": lambda: mix(tone(0.12, 1250, wave_fn=square, vol=0.25, duty=0.3, curve=2), tone(0.12, 1330, vol=0.2, duty=0.3, curve=2), noise(0.04, 0.4, lowpass=0.8)),
    "shot_ball": lambda: tone(0.12, 900, 380, vol=0.45, duty=0.25),
    "shot_bolt": lambda: mix(tone(0.1, 2200, 600, vol=0.35, duty=0.15), noise(0.08, 0.5, lowpass=0.9, highpass=0.5)),
    "shot_fire": lambda: mix(noise(0.22, 0.8, lowpass=0.22, curve=0.9, attack=0.02), tone(0.15, 300, 180, vol=0.2, duty=0.5)),
    "shot_arrow": lambda: tone(0.11, 1500, 900, wave_fn=math.sin, vol=0.7),
    "shot_heavy": lambda: mix(tone(0.2, 420, 110, vol=0.5, duty=0.5), noise(0.18, 0.8, lowpass=0.3)),
    # Hiệu ứng trạng thái
    "burn": lambda: seq(*[noise(0.035, 0.6, lowpass=0.6, seed=s) for s in range(6)], gap=0.025),
    "shock": lambda: mix(tone(0.32, 62, vol=0.45, duty=0.5, trem=0.8, trem_rate=40), noise(0.32, 0.5, lowpass=0.9, highpass=0.6, curve=0.6)),
    "freeze": lambda: mix(tone(0.4, 2600, 1200, wave_fn=math.sin, vol=0.4, curve=0.8), *[bell(0.25, 1800 + 300 * k, 0.15) for k in range(3)], offsets=[0, 0, 0.08, 0.16]),
    "stun": lambda: seq(bell(0.11, 1400, 0.4), bell(0.11, 1700, 0.4), bell(0.2, 2000, 0.4)),
    # Di chuyển, trúng đòn
    "jump": lambda: tone(0.1, 280, 620, vol=0.35, duty=0.25),
    "dodge": lambda: noise(0.18, 0.55, lowpass=0.4, curve=0.6, attack=0.03, highpass=0.2),
    "hurt": lambda: mix(tone(0.2, 420, 140, vol=0.5, duty=0.5), noise(0.08, 0.5, lowpass=0.4)),
    "break": lambda: mix(noise(0.6, 0.9, lowpass=0.95, highpass=0.4, curve=1.4), tone(0.6, 900, 120, vol=0.4, duty=0.3)),
    "ko": lambda: seq(tone(0.25, 520, 390, vol=0.4), tone(0.25, 390, 290, vol=0.4), tone(0.6, 290, 90, vol=0.45)),
    "enemy_die": lambda: mix(noise(0.35, 0.9, lowpass=0.5, curve=1.3), tone(0.3, 300, 50, vol=0.45, duty=0.5)),
    "enemy_shot": lambda: tone(0.14, 520, 260, vol=0.35, duty=0.5),
    "boss_appear": lambda: mix(tone(1.2, 55, 45, vol=0.6, duty=0.5, trem=0.5, trem_rate=6), noise(1.2, 0.5, lowpass=0.1, curve=0.6, attack=0.3)),
    # Vật phẩm, biến thân, tuyệt chiêu
    "pickup": lambda: arp([76, 79, 84, 88], step=0.045, vol=0.4, last=0.15),
    "pickup_key": lambda: arp([72, 76, 79, 84, 79, 84, 88], step=0.07, vol=0.45, last=0.4),
    "henshin_charge": lambda: mix(tone(1.0, 180, 1400, vol=0.35, duty=0.25, vib=0.02, vib_rate=14, curve=0.4, attack=0.1),
                                  noise(1.0, 0.25, lowpass=0.3, curve=0.3, attack=0.4)),
    "henshin_flash": lambda: mix(noise(0.5, 0.7, lowpass=0.9, curve=1.6), *[tone(0.6, note_hz(m), vol=0.18, duty=0.25, curve=1.4) for m in (72, 76, 79, 84)]),
    "form_change": lambda: mix(arp([67, 71, 74, 79], step=0.04, vol=0.35, last=0.12), noise(0.25, 0.4, lowpass=0.5, curve=0.8)),
    "final_charge": lambda: tone(0.7, 220, 1760, vol=0.4, duty=0.25, trem=0.6, trem_rate=18, curve=0.2, attack=0.05),
    "final_impact": lambda: mix(boom(0.9, 1.0), tone(0.5, 1200, 200, vol=0.2, duty=0.5)),
    "rage_full": lambda: seq(tone(0.08, 1046, vol=0.35, duty=0.25), tone(0.18, 1568, vol=0.35, duty=0.25)),
    "clock_up": lambda: mix(noise(0.5, 0.6, lowpass=0.3, curve=0.2, attack=0.45), tone(0.7, 900, 140, wave_fn=math.sin, vol=0.5, curve=0.6)),
    # Giao diện, hội thoại
    "ui_move": lambda: tone(0.035, 1300, vol=0.25, duty=0.5),
    "ui_ok": lambda: seq(tone(0.05, 880, vol=0.3, duty=0.25), tone(0.09, 1320, vol=0.3, duty=0.25)),
    "ui_back": lambda: seq(tone(0.05, 990, vol=0.3, duty=0.25), tone(0.08, 660, vol=0.3, duty=0.25)),
    "text_blip": lambda: tone(0.025, 1500, vol=0.15, duty=0.5),
    # Tiếng biến thân riêng từng Rider (phát cùng giọng đai), theo món đồ biến thân trong phim
    "henshin_kuuga": lambda: mix(tone(1.0, 70, 160, wave_fn=saw, vol=0.35, trem=0.5, trem_rate=10, curve=0.3), bell(0.8, 660, 0.25), offsets=[0, 0.45]),
    "henshin_agito": lambda: mix(bell(1.0, 880, 0.35), bell(1.0, 1320, 0.25), bell(1.0, 1760, 0.2), offsets=[0, 0.12, 0.24]),
    "henshin_ryuki": lambda: echo(tone(0.5, 2400, 600, wave_fn=math.sin, vol=0.4, curve=0.6), 0.09, 0.45, 4),
    "henshin_faiz": lambda: seq(dtmf("5"), dtmf("5"), dtmf("5"), dtmf("#", 0.25), gap=0.07),
    "henshin_blade": lambda: mix(noise(0.18, 0.5, lowpass=0.6, highpass=0.3), bell(0.7, 990, 0.3), offsets=[0, 0.15]),
    "henshin_hibiki": lambda: bell(1.6, 440, 0.6),
    "henshin_kabuto": lambda: mix(tone(0.6, 520, vol=0.25, duty=0.5, trem=0.9, trem_rate=30, curve=0.3), tone(0.05, 2000, vol=0.4), offsets=[0, 0.6]),
    "henshin_den_o": lambda: seq(noise(0.12, 0.4, lowpass=0.5, highpass=0.4), tone(0.1, 1760, vol=0.35, duty=0.25), tone(0.18, 2093, vol=0.35, duty=0.25)),
    "henshin_kiva": lambda: mix(noise(0.08, 0.9, lowpass=0.4), tone(0.08, 300, 120, vol=0.5), *[tone(0.05, 3200, 2600, wave_fn=math.sin, vol=0.25) for _ in range(3)], offsets=[0, 0, 0.2, 0.3, 0.4]),
    "henshin_decade": lambda: seq(noise(0.08, 0.6, lowpass=0.6), tone(0.06, 160, 90, vol=0.6), tone(0.35, 600, 1200, vol=0.3, duty=0.25, trem=0.5, trem_rate=20), gap=0.03),
    "henshin_double": lambda: seq(tone(0.05, 2000, vol=0.4), tone(0.05, 2000, vol=0.4), noise(0.15, 0.7, lowpass=0.5), tone(0.12, 140, 80, vol=0.6), gap=0.08),
    "henshin_ooo": lambda: seq(*[tone(0.12, 900 + 300 * k, 1400 + 300 * k, wave_fn=math.sin, vol=0.4) for k in range(3)], gap=0.04),
    "henshin_fourze": lambda: seq(*[tone(0.04, 1800, vol=0.4) for _ in range(4)], noise(0.2, 0.6, lowpass=0.5), gap=0.09),
    "henshin_wizard": lambda: mix(bell(0.8, 1046, 0.35), tone(0.9, 300, 1200, wave_fn=math.sin, vol=0.25, vib=0.04, curve=0.5), offsets=[0, 0.1]),
    # Gaim: khóa Lockseed cạch, dao Cutting Blade chém "soiya", tiếng tù và ốc (horagai) trầm
    # Drive: xoay Shift Car "cạch", động cơ rú ga lên cao, còi xe hai nốt
    "henshin_drive": lambda: seq(tone(0.04, 1900, vol=0.45), tone(0.6, 90, 420, wave_fn=saw, vol=0.35, trem=0.4, trem_rate=25, curve=0.5),
                                 mix(tone(0.25, 523, vol=0.25, duty=0.5), tone(0.25, 659, vol=0.25, duty=0.5)), gap=0.05),
    # Ghost: bấm mắt Eyecon "cạch", tiếng hồn ma rung (sine vibrato sâu), chuông chùa
    "henshin_ghost": lambda: seq(tone(0.04, 1700, vol=0.45), mix(tone(0.8, 330, 660, wave_fn=math.sin, vol=0.3, vib=0.08, vib_rate=6, curve=0.6),
                                 bell(0.9, 440, 0.25), offsets=[0, 0.35]), gap=0.06),
    # Ex-Aid: cắm Gashat "cạch", nhạc game 8-bit đi lên (arpeggio), tiếng "level up" hai nốt cao
    "henshin_ex_aid": lambda: seq(tone(0.04, 1500, vol=0.45), *[tone(0.06, note_hz(m), vol=0.3, duty=0.25) for m in (72, 76, 79, 84, 88)],
                                  tone(0.12, note_hz(91), vol=0.3, duty=0.125), tone(0.2, note_hz(96), vol=0.3, duty=0.125), gap=0.02),
    # Build: lắc Fullbottle (xóc lạch cạch), quay tay quay Build Driver (tiếng ratchet nhanh dần), "Are you ready" hai nốt
    "henshin_build": lambda: seq(*[noise(0.04, 0.5, lowpass=0.6, highpass=0.3) for _ in range(3)],
                                 *[tone(0.025, 900 + 60 * k, vol=0.3, duty=0.125) for k in range(10)],
                                 tone(0.15, note_hz(79), vol=0.3, duty=0.25), tone(0.25, note_hz(84), vol=0.3, duty=0.25), gap=0.02),
    "henshin_gaim": lambda: seq(tone(0.04, 2200, vol=0.45), noise(0.12, 0.6, lowpass=0.7, highpass=0.4),
                                tone(0.7, 196, 220, wave_fn=saw, vol=0.3, vib=0.03, vib_rate=5, curve=0.4, attack=0.08), gap=0.06),
}


def gen_sfx():
    for name, fn in SFX.items():
        write_wav(os.path.join(OUT, "sfx", name + ".wav"), fn())
    print("Hiệu ứng: %d → audio/sfx/" % len(SFX))


# --- Giọng (đai biến thân, tiếng hô) ---------------------------------------------

# Kiểu giọng: (giọng `say`, tốc độ đọc, chuỗi lọc ffmpeg). "belt" = đai biến thân máy móc; "kivat" = Kivat (dơi nhỏ,
# giọng cao); "hero" = Sora hô biến thân (giọng Nhật).
VOICES = {
    "belt": ("Ralph", 160, "asetrate=22050*0.86,aresample=22050,acrusher=bits=8:mode=log:aa=1,aecho=0.6:0.45:35:0.3,highpass=f=170,volume=2.2"),
    "belt_deep": ("Ralph", 150, "asetrate=22050*0.76,aresample=22050,acrusher=bits=7:mode=log:aa=1,aecho=0.6:0.5:45:0.35,highpass=f=120,volume=2.4"),
    "belt_bright": ("Fred", 170, "asetrate=22050*0.95,aresample=22050,acrusher=bits=9:mode=log:aa=1,aecho=0.5:0.4:30:0.25,highpass=f=220,volume=2.0"),
    "kivat": ("Junior", 180, "asetrate=22050*1.25,aresample=22050,aecho=0.5:0.3:25:0.2,volume=1.8"),
    "hero": ("Reed (Japanese (Japan))", 190, "aecho=0.5:0.3:30:0.15,highpass=f=90,volume=1.8"),
}


def world_voices():
    """{rider: VOICE} đọc từ hằng VOICE trong các file thế giới (dạng {"henshin": [kiểu, câu], ...})."""
    out = {}
    wdir = os.path.join(ROOT, "scripts", "data", "worlds")
    for f in sorted(os.listdir(wdir)):
        if not f.endswith(".gd"):
            continue
        text = open(os.path.join(wdir, f), encoding="utf-8").read()
        m = re.search(r"^const VOICE := \{(.*?)^\}", text, re.S | re.M)
        rid = re.search(r'"rider": &"(\w+)"', text).group(1)
        if m:
            out[rid] = re.findall(r'"(\w+)": \["(\w+)", "([^"]+)"\]', m.group(1))
    return out


def say(style, text, path):
    voice, rate, filt = VOICES[style]
    with tempfile.TemporaryDirectory() as tmp:
        aiff = os.path.join(tmp, "v.aiff")
        subprocess.run(["say", "-v", voice, "-r", str(rate), "-o", aiff, text], check=True)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", aiff, "-af",
                        "aresample=22050," + filt + ",silenceremove=start_periods=1:start_threshold=-45dB",
                        "-ac", "1", "-ar", "22050", path], check=True)


def gen_voice():
    n = 0
    say("hero", "変身!", os.path.join(OUT, "voice", "hero_henshin.wav"))
    say("hero", "超変身!", os.path.join(OUT, "voice", "hero_chou_henshin.wav"))
    n += 2
    for rider, lines in world_voices().items():
        for key, style, text in lines:
            say(style, text, os.path.join(OUT, "voice", "%s_%s.wav" % (rider, key)))
            n += 1
    print("Giọng: %d → audio/voice/" % n)


# --- Nhạc nền chiptune ---------------------------------------------------------------

MAJOR = [0, 2, 4, 5, 7, 9, 11]
MINOR = [0, 2, 3, 5, 7, 8, 10]
PROG_MAJOR = [[0, 4, 5, 3], [0, 3, 4, 0], [5, 3, 0, 4], [0, 5, 3, 4]]
PROG_MINOR = [[0, 5, 2, 6], [0, 3, 4, 0], [0, 6, 5, 4], [0, 5, 6, 4]]
RHYTHMS = [[2, 2, 2, 2], [3, 1, 2, 2], [2, 1, 1, 2, 2], [1, 1, 2, 1, 1, 2], [4, 2, 2], [2, 2, 1, 1, 1, 1], [3, 3, 2]]


def compose(seed, tempo=144, minor=False, bars=16, intensity=1.0, root=57):
    """Một vòng nhạc lặp liền: lead vuông 25%, hoà âm vuông 50% rải hợp âm, bass tam giác, trống nhiễu.
    Cấu trúc A A' B A theo 4 nhịp một đoạn. Trả mẫu âm thanh (float)."""
    rnd = random.Random(seed)
    scale = MINOR if minor else MAJOR
    prog = rnd.choice(PROG_MINOR if minor else PROG_MAJOR)
    prog_b = rnd.choice(PROG_MINOR if minor else PROG_MAJOR)
    beat = 60.0 / tempo
    step = beat / 4                       # 1 ô = nốt móc kép
    steps_bar = 16
    total = int(bars * steps_bar * step * SR)
    out = [0.0] * total

    def deg(d, octave=0):
        return root + 12 * (octave + d // 7) + scale[d % 7]

    def add_note(start_step, length_steps, midi, wave_fn, vol, duty=0.5, curve=0.6):
        s = int(start_step * step * SR)
        part = tone(length_steps * step * 0.95, note_hz(midi), wave_fn=wave_fn, vol=vol, duty=duty, curve=curve)
        for i, v in enumerate(part):
            if s + i < total:
                out[s + i] += v

    def phrase(chords, variant):
        notes = []
        last = rnd.randint(2, 6)
        for bar, chord in enumerate(chords):
            rhythm = RHYTHMS[(rnd.randrange(len(RHYTHMS)) + variant) % len(RHYTHMS)]
            pos = 0
            for i, ln in enumerate(rhythm):
                if i == 0:
                    last = chord + rnd.choice([0, 2, 4])          # phách mạnh: nốt trong hợp âm
                else:
                    last += rnd.choice([-2, -1, -1, 1, 1, 2, 0])
                last = max(0, min(11, last))
                notes.append((bar * 16 + pos * 2, ln * 2, last))
                pos += ln
        return notes

    a = phrase(prog, 0)
    a2 = [(p, l, d + (1 if i % 5 == 3 else 0)) for i, (p, l, d) in enumerate(a)]
    b = phrase(prog_b, 3)
    melody = a + [(p + 64, l, d) for p, l, d in a2] + [(p + 128, l, d) for p, l, d in b] + [(p + 192, l, d) for p, l, d in a]
    for p, l, d in melody:
        add_note(p, l, deg(d, 1), square, 0.16, duty=0.25, curve=0.5)
    chords = prog * 2 + prog_b + prog
    for bar, c in enumerate(chords):
        base = bar * 16
        for k in range(16):                      # bass tam giác: nốt gốc theo móc đơn, nảy quãng tám
            if k % 2 == 0:
                add_note(base + k, 2, deg(c, -1) + (12 if k % 4 == 2 else 0), tri, 0.32, curve=0.3)
        for k in range(8):                       # hoà âm: rải hợp âm
            add_note(base + k * 2, 2, deg(c + [0, 2, 4, 2][k % 4]), square, 0.05 * intensity, duty=0.5, curve=0.8)
    # Trống: kick phách 1, 3 (dồn hơn khi intensity cao), snare phách 2, 4, hi-hat móc đơn
    kick = tone(0.12, 140, 40, wave_fn=math.sin, vol=0.6)
    snare = mix(noise(0.12, 0.35, lowpass=0.7, seed=9), tone(0.08, 220, 150, vol=0.1))
    hat = noise(0.03, 0.12, lowpass=1.0, highpass=0.7, seed=11)
    for bar in range(bars):
        for k in range(16):
            s = int((bar * 16 + k) * step * SR)
            hits = []
            if k in (0, 8) or (intensity > 1.2 and k in (6, 14)):
                hits.append(kick)
            if k in (4, 12):
                hits.append(snare)
            if k % 2 == 0:
                hits.append(hat)
            for h in hits:
                for i, v in enumerate(h):
                    if s + i < total:
                        out[s + i] += v
    return out


def write_mp3(path, samples):
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "m.wav")
        write_wav(wav, samples)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", wav, "-c:a", "libmp3lame",
                        "-b:a", "80k", path], check=True)


def world_ids():
    text = open(os.path.join(ROOT, "scripts", "data", "world_data.gd"), encoding="utf-8").read()
    return re.findall(r'worlds/w\d+_(\w+)\.gd', text)


def gen_music(only=None):
    tracks = {
        "map": dict(seed=7, tempo=112, minor=False, intensity=0.8, root=60),
        "boss": dict(seed=666, tempo=168, minor=True, intensity=1.5, root=52),
        "boss_final": dict(seed=999, tempo=176, minor=True, intensity=1.6, root=50),
    }
    for i, wid in enumerate(world_ids()):
        h = sum(ord(c) * (k + 1) for k, c in enumerate(wid))
        tracks["stage_" + wid] = dict(seed=h, tempo=132 + (h % 5) * 6, minor=bool(h % 3 == 0), intensity=1.0 + (i % 3) * 0.15,
                                      root=55 + h % 7)
    n = 0
    for name, cfg in tracks.items():
        if only and name not in only and name.replace("stage_", "") not in only:
            continue
        write_mp3(os.path.join(OUT, "music", name + ".mp3"), compose(**cfg))
        n += 1
    if not only or "clear" in only:
        jingle = seq(arp([67, 72, 76, 79], step=0.1, vol=0.35, last=0.1), arp([77, 81, 84], step=0.1, vol=0.35, last=0.1),
                     arp([84, 88, 91, 96], step=0.12, vol=0.4, last=0.9))
        write_mp3(os.path.join(OUT, "music", "clear.mp3"), mix(jingle, [v * 0.5 for v in jingle], offsets=[0, 0.01]))
        n += 1
    print("Nhạc: %d → audio/music/" % n)


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("all", "sfx"):
        gen_sfx()
    if what in ("all", "voice"):
        gen_voice()
    if what in ("all", "music"):
        gen_music(sys.argv[2:] or None)


if __name__ == "__main__":
    main()
