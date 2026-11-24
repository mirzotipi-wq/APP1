from pathlib import Path
import subprocess, json, statistics, re, time
root=Path.cwd();out=root/'verification/paired';out.mkdir(exist_ok=True)
revision='3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18'
for index,kind in enumerate(['baseline','candidate','candidate','baseline']):
    binary=root/'verification'/kind/'release/benchmark-study'
    path=out/f'{index+1}-{kind}-frames.json'
    print('START frames',index+1,kind,flush=True);start=time.monotonic()
    with path.open('w') as f:subprocess.run([str(binary),'--samples','3','--revision',revision],stdout=f,check=True)
    print('DONE frames',index+1,kind,round(time.monotonic()-start,3),flush=True)
for index,kind in enumerate(['baseline','candidate','baseline','candidate']):
    binary=root/'verification'/kind/'release/grazing-study-probe'
    path=out/f'{index+1}-{kind}-surfaces.log'
    print('START surfaces',index+1,kind,flush=True)
    with path.open('w') as f:subprocess.run([str(binary),'--bench'],stdout=f,check=True)
    print('DONE surfaces',index+1,kind,flush=True)
summary={'sourceBase':revision,'scope':'Paired sequential shared Linux host measurements; candidate is uncommitted isolated source, not the baseline revision or native/device execution','frames':[],'surfaces':[]}
frame_data={kind:[json.loads(p.read_text()) for p in out.glob(f'*-{kind}-frames.json')] for kind in ['baseline','candidate']}
for name in [x['name'] for x in frame_data['baseline'][0]['frames']]:
    row={'name':name}
    for kind in ['baseline','candidate']:
        frames=[next(x for x in r['frames'] if x['name']==name) for r in frame_data[kind]]
        times=[t for x in frames for t in x['timing']['samplesMilliseconds']]
        row[kind]={'milliseconds':times,'median':statistics.median(times),'minimum':min(times),'maximum':max(times),'hashes':sorted(set(x['rgbaFNV1a64'] for x in frames))}
    row['candidateToBaselineMedian']=row['candidate']['median']/row['baseline']['median'];summary['frames'].append(row)
surface_data={}
for kind in ['baseline','candidate']:
    for p in out.glob(f'*-{kind}-surfaces.log'):
        for line in p.read_text().splitlines():
            m=re.fullmatch(r'BENCH (\w+) (\w+) samples_ms=(\[.*\]) checksum=(.*)',line)
            key=(m[1],m[2]);surface_data.setdefault(key,{}).setdefault(kind,{'times':[],'checksums':[]})
            surface_data[key][kind]['times']+=json.loads(m[3]);surface_data[key][kind]['checksums'].append(float(m[4]))
for (quality,name),values in surface_data.items():
    row={'quality':quality,'name':name}
    for kind in ['baseline','candidate']:
        d=values[kind];row[kind]={'milliseconds':d['times'],'median':statistics.median(d['times']),'checksums':d['checksums']}
    row['candidateToBaselineMedian']=row['candidate']['median']/row['baseline']['median'];summary['surfaces'].append(row)
(out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
for row in summary['frames']:print('FRAME',row['name'],'baseline',round(row['baseline']['median'],3),'candidate',round(row['candidate']['median'],3),'ratio',round(row['candidateToBaselineMedian'],3),flush=True)
for row in summary['surfaces']:print('SURFACE',row['quality'],row['name'],'baseline',round(row['baseline']['median'],3),'candidate',round(row['candidate']['median'],3),'ratio',round(row['candidateToBaselineMedian'],3),flush=True)
