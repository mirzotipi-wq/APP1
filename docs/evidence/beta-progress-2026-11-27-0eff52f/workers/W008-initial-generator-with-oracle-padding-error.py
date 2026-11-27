import itertools,json,random,re
from pathlib import Path
p=Path('/tmp/w008-number-review')
number=re.compile(r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\Z',re.ASCII)
rows=[]
def add(token,kind='token',mode=0,encoding='utf8'):
    rows.append({'value':token,'expected':bool(number.fullmatch(token)) if kind=='token' else True,'mode':mode,'encoding':encoding,'kind':kind})
alphabet='-+.eE0129'
for n in range(1,6):
    for xs in itertools.product(alphabet,repeat=n):
        token=''.join(xs)
        add(token,mode=len(rows)%5)
rng=random.Random(0x8004)
for _ in range(3000):
    integer=rng.choice(['0',str(rng.randrange(1,10**18))])
    token=rng.choice(['','-'])+integer+rng.choice(['','.'+str(rng.randrange(10**12))])+rng.choice(['','e','E'])
    if token[-1:] in ['e','E']:
        token+=rng.choice(['','+','-'])+str(rng.randrange(10**16))
    add(token,mode=rng.randrange(5))
    i=rng.randrange(len(token)+1)
    malformed=token[:i]+rng.choice(['+','-','e','.',' ','\t','\u00a0','\u0660','x','_'])+token[i:]
    add(malformed,mode=rng.randrange(5))
for t in ['-9.005E+330','5e-009','0.000000e999999','12345.000e+0008','1\n2','1\r\n','−1','１','9.99E+','0\u00a0','+0.0','4_5','8e\t1']:
    for enc in ['utf8','utf16be','utf16le','utf32be','utf32le']:
        for mode in range(5):add(t,mode=mode,encoding=enc)
for token in ['0,1','{"7e+":"--4","data":["9.","8e-",{"01":"+1"}]}','[true,false,null,0.0,-2e5,{"x":["-","-0e99"]}]']:
    if token=='0,1':
        rows.append({'value':'0,1','expected':False,'mode':0,'encoding':'utf8','kind':'raw'})
    else:add(token,kind='raw')
for t in ['-','00','1e+','4.','--20','1e2.3','1\n2','0xFF','\u0665.0']:
    add(json.dumps({'value':t,'12e-':t}),kind='raw')
(p/'cases.json').write_text(json.dumps(rows,separators=(',',':')))
(p/'generator-summary.json').write_text(json.dumps({'cases':len(rows),'oracle':'ASCII JSON number grammar via Python re.fullmatch; wrappers are controlled complete JSON','alphabet':alphabet,'exhaustive_max_length':5,'random_seed':0x8004,'valid_expected':sum(x['expected'] for x in rows)},indent=2)+'\n')
print((p/'generator-summary.json').read_text())
