"""Prepara os sons CC0 baixados do OpenGameArt para o jogo (ver art/audio/CREDITOS.md).

Uso: python tools/prepare_audio.py <pasta com os downloads> art/audio
Precisa de ffmpeg e numpy.
"""
import subprocess, sys, os
import numpy as np

SRC, OUT = sys.argv[1], sys.argv[2]
RATE = 44100

def read(path, start=0.0, dur=None, filters=None, channels=1):
    cmd = ["ffmpeg", "-v", "error", "-ss", str(start)]
    if dur:
        cmd += ["-t", str(dur)]
    cmd += ["-i", path]
    if filters:
        cmd += ["-af", filters]
    cmd += ["-ac", str(channels), "-ar", str(RATE), "-f", "f32le", "-"]
    raw = subprocess.run(cmd, check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).reshape(-1, channels).copy()

def write(name, data, quality=4):
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    ch = data.shape[1]
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", str(ch), "-i", "-",
                    "-c:a", "libvorbis", "-q:a", str(quality), path], input=data.astype(np.float32).tobytes(), check=True)
    print(name, round(len(data) / RATE, 2), "s")

def rms_norm(data, target_db):
    rms = np.sqrt(np.mean(data ** 2)) + 1e-9
    data = data * (10 ** (target_db / 20) / rms)
    peak = np.max(np.abs(data))
    return data / peak * 0.95 if peak > 0.95 else data

def peak_norm(data, peak_db=-3.0):
    peak = np.max(np.abs(data)) + 1e-9
    return data * (10 ** (peak_db / 20) / peak)

def seamless(data, fade=2.0):
    """Loop sem emenda: a cauda é misturada ao começo e cortada do fim."""
    n = int(fade * RATE)
    head, tail = data[:n], data[-n:]
    t = np.linspace(0, 1, n)[:, None]
    mixed = head * np.sqrt(t) + tail * np.sqrt(1 - t)
    return np.concatenate([mixed, data[n:-n]])

def trim(data, thresh_db=-45):
    env = np.max(np.abs(data), axis=1)
    idx = np.where(env > 10 ** (thresh_db / 20))[0]
    if len(idx) == 0:
        return data
    a, b = max(0, idx[0] - 200), min(len(data), idx[-1] + 2000)
    out = data[a:b].copy()
    fade = min(len(out) // 4, 2000)
    out[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return out

x = lambda *p: os.path.join(SRC, "x", *p)
s = lambda *p: os.path.join(SRC, *p)

# Ambientes e música (loops, estéreo onde faz diferença)
write("ambiente/jazz_1923.ogg", seamless(rms_norm(read(s("Jazz Take 2.wav"), filters="highpass=f=180,lowpass=f=2600", channels=2), -20)), 3)
write("ambiente/burburinho_1923.ogg", seamless(rms_norm(read(s("montageAudio-20120409@020248.mp3"), 0, 56, "lowpass=f=1800", 2), -24)), 3)
write("ambiente/vento_hoje.ogg", seamless(rms_norm(read(s("wind background noise 2.wav"), channels=2), -24)), 3)
write("ambiente/goteiras_hoje.ogg", seamless(rms_norm(read(s("atmo.mp3"), channels=2), -30), 1.0), 3)
write("ambiente/tique_relogio.ogg", seamless(rms_norm(read(s("ticking_clock.wav")), -26), 0.05), 4)

# Passos (madeira/piso), seis variações
for i in range(1, 7):
    name = "01-footstep_0.ogg" if i == 1 else "%02d-footstep.ogg" % i
    write("efeitos/passo_%d.ogg" % i, peak_norm(trim(read(s(name))), -6))

fx = {
    "porta_abre": x("100-CC0-wood-metal-SFX", "door_open_01.ogg"),
    "porta_fecha": x("100-CC0-wood-metal-SFX", "wood_close_01.ogg"),
    "porta_trancada": x("DoorLockSounds", "DoorLockSounds", "LockedDoorHandleJiggle.wav"),
    "destrancar": x("DoorLockSounds", "DoorLockSounds", "UnlockDoor.wav"),
    "fechadura_abre": x("100-CC0-wood-metal-SFX", "lock_open_01.ogg"),
    "chave": x("100-CC0-wood-metal-SFX", "keys_01.ogg"),
    "pagina_1": x("book_flips_-_starninjas", "book_flip.1.ogg"),
    "pagina_2": x("book_flips_-_starninjas", "book_flip.2.ogg"),
    "pagina_3": x("book_flips_-_starninjas", "book_flip.3.ogg"),
    "papel": x("100-CC0-SFX_0", "paper_01.ogg"),
    "tique": x("ticks", "ticking clock - tick1.wav"),
    "corda": s("singlewind1.wav"),
    "troca_epoca": x("swishes", "swishes", "swish-9.wav"),
    "mecanismo": x("100-CC0-wood-metal-SFX", "metal_open_01.ogg"),
    "alavanca": x("100-CC0-SFX_0", "switch_01.ogg"),
    "botao": x("100-CC0-SFX_0", "switch_02.ogg"),
    "madeira_range": x("100-CC0-wood-metal-SFX", "wood_squeak_01.ogg"),
    "madeira_quebra": x("100-CC0-wood-metal-SFX", "wood_breaking_01.ogg"),
    "metal_pancada": x("100-CC0-wood-metal-SFX", "metal_hit_01.ogg"),
    "pegar": x("100-CC0-wood-metal-SFX", "misc_01.ogg"),
    "dobradica": s("creaky_door_hinge.wav"),
    "batidas": x("100-CC0-SFX_0", "door_01.ogg"),
    "sino": x("100-CC0-SFX_0", "bell_01.ogg"),
}
for name, path in fx.items():
    write("efeitos/%s.ogg" % name, peak_norm(trim(read(path)), -4))

# Piano: sem notas soltas CC0, as 8 teclas brancas (dó 4 a dó 5) são sintetizadas
freqs = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25]
for i, f in enumerate(freqs):
    t = np.arange(int(2.2 * RATE)) / RATE
    tone = np.zeros_like(t)
    for k, amp in enumerate([1.0, 0.55, 0.32, 0.2, 0.12, 0.07, 0.04]):
        h = (k + 1) * f * (1 + 0.0004 * k * k)  # leve desafinação inarmônica, como corda real
        tone += amp * np.sin(2 * np.pi * h * t) * np.exp(-t * (1.6 + 1.1 * k))
    attack = np.minimum(1, t / 0.004)
    hammer = np.random.default_rng(i).normal(0, 1, len(t)) * np.exp(-t * 60) * 0.05
    note = (tone * attack + hammer)[:, None]
    write("efeitos/piano_%d.ogg" % (i + 1), peak_norm(note, -5))
