"""Synthesize the Cryo-Vex ice and Vespera maglev environmental event cues."""
from pathlib import Path
import wave
import numpy as np
from scipy.signal import butter, sosfilt

RATE = 24000
OUT = Path(__file__).resolve().parents[1] / "current_dev/assets/hazards"
rng = np.random.default_rng(1968)


def clock(length):
    return np.arange(round(RATE * length)) / RATE


def band(noise, lo, hi):
    return sosfilt(butter(3, [lo, hi], btype="bandpass", fs=RATE, output="sos"), noise)


def chirp(time, frequency):
    return np.sin(np.cumsum(np.broadcast_to(frequency, time.shape)) * (2*np.pi/RATE))


def add(buffer, at, sample):
    start = round(at * RATE)
    count = min(len(sample), len(buffer) - start)
    buffer[start:start+count] += sample[:count]


def rings(t, tones, decay):
    return sum(chirp(t, f) * np.exp(-t * (1+i*.29)/decay) / (1+i*.6)
               for i, f in enumerate(tones))


def crackle(buffer, count, duration, metallic=False):
    for _ in range(count):
        at = rng.uniform(.09, duration)
        t = clock(rng.uniform(.06, .25))
        pitch = rng.uniform(890, 3500)
        glass = rings(t, [pitch, pitch*1.48, pitch*1.93], .032 if metallic else .018)
        onset = band(rng.normal(size=len(t)), 1200, 7800) * np.exp(-t*155)
        add(buffer, at, (glass+onset) * np.exp(-at/duration) * rng.uniform(.04,.23))


def ice_warning():
    t = clock(2.4)
    stress = (chirp(t, 53+4*t+3*np.sin(t*4)) + .31*chirp(t, 83+14*t))
    x = stress*.21*np.sin(np.pi*t/2.5)**1.3
    for at, f in [(.08,1030),(.47,770),(.81,1220),(1.38,1490),(1.57,990),(2.03,1590)]:
        u=clock(.34)
        # A bending ice sheet disperses the fracture into a downward pitch glide.
        c=chirp(u, f*np.exp(-u*11)+105)*np.exp(-u*12)
        add(x,at,c*.44)
        add(x,at+.065,c*.12)
    return x


def ice_impact():
    t=clock(2.20)
    n=rng.normal(size=len(t))
    x=(.82*chirp(t,43+66*np.exp(-t*11))+.70*band(n,35,790))*np.exp(-t*6)
    x+=band(n,480,5800)*np.exp(-t*2.4)*(.27+.10*np.cos(t*21))
    crackle(x,58,1.85)
    return x


def rail_warning():
    t=clock(2.42)
    envelope=np.sin(np.pi*.54*t/2.43)**1.8
    step=np.maximum(t-1.45,0)
    wheel=chirp(t,612+195*t+24*np.sin(t*9)-180*step)
    horn=rings(t,[177,223,267,351],5.0)
    scrape=band(rng.normal(size=len(t)),800,2500)*(1+.5*np.sin(t*69))
    return envelope*(wheel*.17+horn*.29+scrape*.22+chirp(t,58+t*20)*.21)


def rail_impact():
    t=clock(2.36)
    n=rng.normal(size=len(t))
    x=.62*chirp(t,39+78*np.exp(-t*17))*np.exp(-t*6)
    for at,level in [(0,.85),(.10,.51),(.32,.36),(.66,.23)]:
        u=clock(.67)
        hit=.45*rings(u,[82,137,247,397,631,937],.20)
        hit+=band(rng.normal(size=len(u)),180,4800)*np.exp(-u*24)
        add(x,at,hit*level)
    x+=band(n,510,2660)*np.sin(np.pi*t/2.36)**.8*np.exp(-t*1.9)*.64
    crackle(x,38,1.60,True)
    return x


def beast_warning():
    t=clock(2.34)
    # A slow inhalation gives way to a voiced bellow. Modulated harmonics
    # carry two formants while the air loosens into an irregular rasp.
    f=48 + 17*np.sin(np.pi*t/2.35)**2 + 2.9*np.sin(t*17)
    phase=np.cumsum(f)*(2*np.pi/RATE)
    throat=np.zeros_like(t)
    for k in range(1,28):
        g=.065+np.exp(-((k*f-(350-39*t))/115)**2)+.44*np.exp(-((k*f-1020)/235)**2)
        throat+=g*np.sin(phase*k+.13*np.sin(phase))/(1+k*.26)
    n=rng.normal(size=len(t))
    attack=np.clip((t-.31)/.38,0,1)
    envelope=np.sin(np.pi*np.clip((t-.30)/2.1,0,1))**.65
    return band(n,160,1750)*.19*np.exp(-((t-.30)/.29)**2)+attack*envelope*(
        throat*(.75+.18*np.sin(phase*.53))+band(n,260,2100)*.22)


def beast_impact():
    t=clock(1.83)
    x=np.zeros_like(t)
    for at,level in [(0,1),(.054,.72),(.23,.20)]:
        u=clock(.85)
        thud=chirp(u,39+70*np.exp(-u*18))*np.exp(-u*7)
        snarl=band(rng.normal(size=len(u)),90,2900)*np.exp(-u*18)
        add(x,at,(thud+.90*snarl)*level)
    crackle(x,36,1.15)
    g=clock(.77)
    phase=np.cumsum(55+19*np.sin(np.pi*g/.77))*(2*np.pi/RATE)
    grunt=(np.sin(phase)+.34*np.sin(phase*5)+.19*np.sin(phase*8))*.31
    add(x,.16,grunt*np.sin(np.pi*g/.77)**1.5)
    return x


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, create in [("cryo_warning",ice_warning),("cryo_impact",ice_impact),
                         ("vespera_warning",rail_warning),("vespera_impact",rail_impact),
                         ("cryo_creature_warning",beast_warning),("cryo_creature_impact",beast_impact)]:
        pcm=create()
        pcm *= np.minimum(clock(len(pcm)/RATE)/.006,1)
        pcm[-1800:] *= np.linspace(1,0,1800)
        pcm=np.tanh(pcm*1.28)
        with wave.open(str(OUT/(name+".wav")), "wb") as wav:
            wav.setparams((1,2,RATE,0,"NONE","not compressed"))
            wav.writeframes((pcm * (.88/np.max(np.abs(pcm))) * 32767).astype("<i2").tobytes())
