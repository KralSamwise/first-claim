"""Original deterministic game Foley synthesis, no downloaded or generated-service audio."""
from pathlib import Path
import array, hashlib, json, math, random, wave

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/audio';OUT.mkdir(exist_ok=True)
RATE=32000
records=[]

def write(name,seconds,kind,seed):
    rng=random.Random(seed);length=int(seconds*RATE)
    data=array.array('h');low=0.;slow=0.
    # Each surface has its own excitation, resonances and decay envelope.
    impacts=[]
    if kind in ('gravel','step'):
        for j in range(42 if kind=='gravel' else 17):
            impacts.append((rng.uniform(0,seconds*.72),rng.uniform(650,3800),rng.uniform(.025,.075),rng.uniform(.1,.35)))
    peak=0.;square=0.
    for i in range(length):
        t=i/RATE;n=rng.uniform(-1,1);low+=.09*(n-low);slow+=.008*(n-slow)
        if kind=='river':
            value=low*.7+(n-low)*.045
            value*=.65+.14*math.sin(t*1.1)+.08*math.sin(t*.37)
            value+=.015*math.sin(2*math.pi*(390*t+10*math.sin(t*2.4)))*math.sin(t*3.7)**8
        elif kind=='forest':
            value=slow*(.45+.15*math.sin(t*.4))
        elif kind=='water':
            value=(low*.62+(n-low)*.09)*math.sin(math.pi*min(1,t/seconds))**.45
            value+=.025*math.sin(2*math.pi*(270*t+18*math.sin(t*8)))*math.exp(-t*2)
        elif kind in ('gravel','step'):
            value=n*.055*math.exp(-t*7)
            for at,freq,decay,amp in impacts:
                d=t-at
                if 0<=d<decay*5:value+=amp*math.exp(-d/decay)*(math.sin(2*math.pi*freq*d)*.22+n*.25)
        elif kind=='wood':
            value=n*.25*math.exp(-t*95)
            for freq,amp,decay in [(135,.32,11),(327,.17,20),(792,.10,35)]:value+=amp*math.sin(2*math.pi*freq*t)*math.exp(-t*decay)
        elif kind=='rock':
            value=(n-low)*.42*math.exp(-t*55)+low*.3*math.exp(-t*13)
            for freq,amp in [(720,.17),(1430,.09),(2370,.05)]:value+=amp*math.sin(2*math.pi*freq*t)*math.exp(-t*22)
        elif kind=='gold':
            value=sum(amp*math.sin(2*math.pi*freq*t)*math.exp(-t*decay) for freq,amp,decay in [(1850,.16,13),(2927,.1,18),(4310,.04,24)])
        elif kind=='pour':
            envelope=math.sin(math.pi*t/seconds)**.5
            value=(low*.6+n*.045)*envelope+.035*math.sin(2*math.pi*(180*t+7*math.sin(t*12)))*envelope
        elif kind=='creak':
            envelope=math.sin(math.pi*t/seconds)**.8
            value=(math.sin(2*math.pi*(87*t+5*math.sin(t*2)))+math.sin(2*math.pi*(194*t+2*math.sin(t*3))))*.10*envelope+low*.1*envelope
        elif kind=='fall':
            envelope=min(1,t*35)*math.exp(-t*2.8)
            value=(low*.9+n*.15)*envelope+.07*math.sin(2*math.pi*64*t)*envelope
        else:raise ValueError(kind)
        if kind not in ('river','forest'):value*=min(1,t*1500)*min(1,(seconds-t)*80)
        peak=max(peak,abs(value));square+=value*value
        data.append(round(max(-.95,min(.95,value))*32767))
    path=OUT/(name+'.wav')
    with wave.open(str(path),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(data.tobytes())
    records.append({'id':name,'file':str(path),'source':'Original deterministic Python Foley synthesis','license':'Original project asset','duration':seconds,'sample_rate':RATE,'peak':peak,'rms':math.sqrt(square/length),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})

for index,(name,seconds,kind) in enumerate([
    ('river',12,'river'),('forest',12,'forest'),('water',1.6,'water'),
    ('gravel',.75,'gravel'),('step',.32,'step'),('wood',.55,'wood'),
    ('rock',.6,'rock'),('gold',.42,'gold'),('pour',1.8,'pour'),
    ('creak',1.15,'creak'),('fall',1.4,'fall')]):write(name,seconds,kind,440+index)
(OUT/'manifest.json').write_text(json.dumps({'schema':1,'assets':records},indent=2))
print('ORIGINAL_AUDIO_EXPORTED',len(records))
