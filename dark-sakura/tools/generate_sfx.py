#!/usr/bin/env python3
import wave
import struct
import math
import random
import os

SAMPLE_RATE = 22050

def write_wav(filename, samples):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'wb') as wav_file:
        wav_file.setnchannels(1) # mono
        wav_file.setsampwidth(2) # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        
        packed = bytearray()
        for s in samples:
            # Clamp to 16-bit signed integer
            clamped = max(-1.0, min(1.0, s))
            val = int(clamped * 32767.0)
            packed.extend(struct.pack('<h', val))
        wav_file.writeframes(packed)
    print(f"Generated: {filename} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def make_gunshot():
    duration = 0.45
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Deep explosive sub-bass sweep (240Hz -> 28Hz)
        freq = 240.0 * math.exp(-t * 26.0) + 28.0
        phase = 2.0 * math.pi * freq * t
        sub_kick = math.sin(phase) * math.exp(-t * 7.5) * 1.3
        
        # Harsh explosive transient crack (initial 25ms blast)
        crack_noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 40.0) * 1.2
        # Secondary air / powder blast
        body_noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 16.0) * 0.4
        
        # Heavy metallic slide & chamber resonance
        ring1 = math.sin(2.0 * math.pi * 520.0 * t) * math.exp(-t * 18.0) * 0.45
        ring2 = math.sin(2.0 * math.pi * 960.0 * t) * math.exp(-t * 24.0) * 0.3
        
        # Overdrive and tape saturation for maximum punch
        raw = sub_kick + crack_noise + body_noise + ring1 + ring2
        clipped = math.tanh(raw * 2.2)
        samples.append(clipped * 0.98)
    return samples

def make_dry_click():
    duration = 0.08
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        click1 = math.sin(2.0 * math.pi * 1400.0 * t) * math.exp(-t * 80.0)
        click2 = 0.0
        if t > 0.018:
            t2 = t - 0.018
            click2 = math.sin(2.0 * math.pi * 2200.0 * t2) * math.exp(-t2 * 110.0) * 0.7
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 120.0) * 0.3
        samples.append((click1 + click2 + noise) * 0.75)
    return samples

def make_reload():
    duration = 0.75
    num_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * num_samples
    
    # Event 1: Mag out at t=0.08
    t1 = 0.08
    # Event 2: Mag in at t=0.38
    t2 = 0.38
    # Event 3: Slide rack at t=0.55
    t3 = 0.55
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        # Mag out click
        if 0 <= (t - t1) < 0.08:
            dt = t - t1
            val += math.sin(2.0 * math.pi * 950.0 * dt) * math.exp(-dt * 60.0) * 0.5
            val += (random.random() * 2.0 - 1.0) * math.exp(-dt * 90.0) * 0.3
        # Mag in clack
        if 0 <= (t - t2) < 0.1:
            dt = t - t2
            val += math.sin(2.0 * math.pi * 650.0 * dt) * math.exp(-dt * 50.0) * 0.65
            val += (random.random() * 2.0 - 1.0) * math.exp(-dt * 70.0) * 0.4
        # Slide rack
        if 0 <= (t - t3) < 0.15:
            dt = t - t3
            f = 1200.0 - dt * 3000.0
            val += math.sin(2.0 * math.pi * max(200.0, f) * dt) * math.exp(-dt * 30.0) * 0.8
            val += (random.random() * 2.0 - 1.0) * math.exp(-dt * 45.0) * 0.4
        samples[i] = val * 0.8
    return samples

def make_hit_normal():
    duration = 0.07
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Crisp blip / thud
        tone = math.sin(2.0 * math.pi * 920.0 * t) * math.exp(-t * 55.0)
        thud = math.sin(2.0 * math.pi * 210.0 * t) * math.exp(-t * 40.0) * 0.5
        samples.append((tone + thud) * 0.7)
    return samples

def make_hit_headshot():
    duration = 0.16
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Bright high bell ding + crack
        bell1 = math.sin(2.0 * math.pi * 1840.0 * t) * math.exp(-t * 28.0)
        bell2 = math.sin(2.0 * math.pi * 2760.0 * t) * math.exp(-t * 35.0) * 0.45
        crack = (random.random() * 2.0 - 1.0) * math.exp(-t * 90.0) * 0.35
        samples.append((bell1 + bell2 + crack) * 0.85)
    return samples

def make_melee_hit():
    duration = 0.22
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        thump = math.sin(2.0 * math.pi * 85.0 * t) * math.exp(-t * 18.0)
        crunch = (random.random() * 2.0 - 1.0) * math.exp(-t * 35.0) * 0.6
        samples.append(math.tanh((thump + crunch) * 1.5) * 0.9)
    return samples

def make_dash():
    duration = 0.28
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Fast swoosh of filtered noise
        env = math.sin(math.pi * (t / duration)) ** 2
        f = 300.0 + (t / duration) * 800.0
        tone = math.sin(2.0 * math.pi * f * t) * 0.3
        noise = (random.random() * 2.0 - 1.0) * 0.7
        samples.append((tone + noise) * env * 0.75)
    return samples

def make_footstep(variant=1):
    duration = 0.11
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    base_f = 110.0 if variant == 1 else 95.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        thud = math.sin(2.0 * math.pi * base_f * t) * math.exp(-t * 40.0)
        scuff = (random.random() * 2.0 - 1.0) * math.exp(-t * 60.0) * 0.3
        samples.append((thud + scuff) * 0.45)
    return samples

def make_player_hurt():
    duration = 0.25
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        thud = math.sin(2.0 * math.pi * 65.0 * t) * math.exp(-t * 15.0)
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 25.0) * 0.5
        samples.append(math.tanh((thud + noise) * 1.4) * 0.8)
    return samples

def make_enemy_screech():
    # ChonChon screech: screeching FM modulation
    duration = 0.35
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        mod = math.sin(2.0 * math.pi * 45.0 * t) * 350.0
        carrier = math.sin(2.0 * math.pi * (750.0 + mod) * t)
        noise = (random.random() * 2.0 - 1.0) * 0.25
        env = math.sin(math.pi * (t / duration))
        samples.append((carrier + noise) * env * 0.6)
    return samples

def make_enemy_growl():
    # Wrapper growl: low gutter rumble
    duration = 0.45
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        mod = math.sin(2.0 * math.pi * 25.0 * t) * 60.0
        carrier = math.sin(2.0 * math.pi * (85.0 + mod) * t)
        noise = (random.random() * 2.0 - 1.0) * 0.45
        env = math.sin(math.pi * (t / duration))
        samples.append(math.tanh((carrier + noise) * 1.6) * env * 0.7)
    return samples

def make_boss_roar():
    # Aberration boss roar
    duration = 1.1
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        mod = math.sin(2.0 * math.pi * 15.0 * t) * 80.0
        carrier = math.sin(2.0 * math.pi * (58.0 + mod) * t)
        sub = math.sin(2.0 * math.pi * 38.0 * t) * 0.8
        noise = (random.random() * 2.0 - 1.0) * 0.5
        env = math.sin(math.pi * (t / duration)) ** 0.8
        samples.append(math.tanh((carrier + sub + noise) * 2.0) * env * 0.85)
    return samples

def make_seal_pickup():
    # Mystical ethereal chime (Japanese Insen pentatonic arpeggio)
    duration = 0.95
    num_samples = int(duration * SAMPLE_RATE)
    notes = [440.0, 466.16, 587.33, 659.25, 783.99] # A, Bb, D, E, G
    samples = [0.0] * num_samples
    
    for idx, freq in enumerate(notes):
        start_t = idx * 0.08
        start_sample = int(start_t * SAMPLE_RATE)
        for i in range(start_sample, num_samples):
            t = (i - start_sample) / SAMPLE_RATE
            tone = math.sin(2.0 * math.pi * freq * t) * math.exp(-t * 4.5)
            harmonic = math.sin(2.0 * math.pi * freq * 2.0 * t) * math.exp(-t * 7.0) * 0.4
            samples[i] += (tone + harmonic) * 0.25
    return samples

def make_heartbeat():
    # Low-end double thump (lub-dub)
    duration = 0.55
    num_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # First thump
        val = 0.0
        if t < 0.18:
            val += math.sin(2.0 * math.pi * 48.0 * t) * math.exp(-t * 18.0) * 0.8
        # Second thump at 0.16s
        if 0.16 <= t < 0.38:
            dt = t - 0.16
            val += math.sin(2.0 * math.pi * 54.0 * dt) * math.exp(-dt * 20.0) * 0.6
        samples[i] = math.tanh(val * 1.5) * 0.9
    return samples

def make_ember_pickup():
    duration = 0.18
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        f = 600.0 + (t / duration) * 800.0
        tone = math.sin(2.0 * math.pi * f * t) * math.exp(-t * 12.0)
        samples.append(tone * 0.4)
    return samples

if __name__ == '__main__':
    write_wav('Audio/SFX/gun_shoot.wav', make_gunshot())
    write_wav('Audio/SFX/gun_empty.wav', make_dry_click())
    write_wav('Audio/SFX/gun_reload.wav', make_reload())
    write_wav('Audio/SFX/hit_normal.wav', make_hit_normal())
    write_wav('Audio/SFX/hit_headshot.wav', make_hit_headshot())
    write_wav('Audio/SFX/melee_hit.wav', make_melee_hit())
    write_wav('Audio/SFX/player_dash.wav', make_dash())
    write_wav('Audio/SFX/player_footstep1.wav', make_footstep(1))
    write_wav('Audio/SFX/player_footstep2.wav', make_footstep(2))
    write_wav('Audio/SFX/player_hurt.wav', make_player_hurt())
    write_wav('Audio/SFX/enemy_screech.wav', make_enemy_screech())
    write_wav('Audio/SFX/enemy_growl.wav', make_enemy_growl())
    write_wav('Audio/SFX/boss_roar.wav', make_boss_roar())
    write_wav('Audio/SFX/seal_pickup.wav', make_seal_pickup())
    write_wav('Audio/SFX/heartbeat.wav', make_heartbeat())
    write_wav('Audio/SFX/ember_pickup.wav', make_ember_pickup())
    print("ALL SFX GENERATED SUCCESSFULLY!")
