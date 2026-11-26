from pathlib import Path
import hashlib, json, platform, struct, subprocess, sys, zlib
ROOT=Path('/tmp/keyfill03-7f4b/workers/W72-geometry')
E=ROOT/'docs/parallel/03/evidence'
OUT=Path('/tmp/keyfill03-7f4b/builds/W72-geometry')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def png(p, decode=True):
    data=p.read_bytes(); assert data[:8]==b'\x89PNG\r\n\x1a\n'
    pos=8; chunks=[]; packed=b''; ihdr=None
    while pos<len(data):
        n=struct.unpack('>I',data[pos:pos+4])[0]; typ=data[pos+4:pos+8]; payload=data[pos+8:pos+8+n]; crc=struct.unpack('>I',data[pos+8+n:pos+12+n])[0]
        assert zlib.crc32(typ+payload)&0xffffffff==crc, (p,typ)
        chunks.append(typ.decode()); pos+=12+n
        if typ==b'IHDR': ihdr=struct.unpack('>IIBBBBB',payload)
        if typ==b'IDAT': packed+=payload
        if typ==b'IEND': break
    assert pos==len(data) and ihdr
    w,h,depth,ct,comp,filt,interlace=ihdr
    meta=dict(width=w,height=h,bitDepth=depth,colorType=ct,chunks=chunks,crcValid=True,sha256=sha(p))
    if not decode:return meta,None
    assert depth==8 and ct in (2,6) and (comp,filt,interlace)==(0,0,0)
    bpp={2:3,6:4}[ct]; stride=w*bpp; raw=zlib.decompress(packed); assert len(raw)==h*(stride+1)
    prev=bytearray(stride); pixels=bytearray(); filters=[]
    def paeth(a,b,c):
        q=a+b-c; ds=[abs(q-a),abs(q-b),abs(q-c)]; return (a,b,c)[ds.index(min(ds))]
    for y in range(h):
        f=raw[y*(stride+1)]; filters.append(f); row=bytearray(raw[y*(stride+1)+1:(y+1)*(stride+1)]); assert f in range(5)
        for x in range(stride):
            a=row[x-bpp] if x>=bpp else 0; b=prev[x]; c=prev[x-bpp] if x>=bpp else 0
            predictor=(0,a,b,(a+b)//2,paeth(a,b,c))[f]; row[x]=(row[x]+predictor)&255
        pixels.extend(row);prev=row
    meta['filters']=sorted(set(filters));meta['decodedByteCount']=len(pixels)
    return meta,bytes(pixels)
def ppm(p):
    data=p.read_bytes(); pos=0; tokens=[]
    while len(tokens)<4:
        while data[pos:pos+1].isspace():pos+=1
        if data[pos:pos+1]==b'#':pos=data.index(b'\n',pos)+1;continue
        start=pos
        while pos<len(data) and not data[pos:pos+1].isspace():pos+=1
        tokens.append(data[start:pos])
    assert tokens[0]==b'P6' and int(tokens[3])==255 and data[pos:pos+1].isspace()
    pos+=2 if data[pos:pos+2]==b'\r\n' else 1
    w,h=map(int,tokens[1:3]); rgb=data[pos:];assert len(rgb)==w*h*3
    return dict(width=w,height=h,maxValue=255,channels=3,decodedByteCount=len(rgb),sha256=sha(p)),rgb
original=json.loads((E/'original/manifest.json').read_text()); final=json.loads((E/'final/manifest.json').read_text());lookup={x['name']:x for x in final}
results=[]
for f in original['fixtures']:
    name=f['name']; w,h=f['width'],f['height']; records={}; decoded={}
    for stage in ['original','final']:
        pm,pr=ppm(E/stage/(name+'.ppm'));im,ir=png(E/stage/(name+'.png'))
        assert (pm['width'],pm['height'])==(w,h)==(im['width'],im['height'])
        assert im['colorType']==2 and pr==ir
        records[stage]={'ppm':pm,'png':im,'sceneSHA256':sha(E/stage/(name+'.json'))};decoded[stage]=pr
    rgba=(E/'final'/(name+'.rgba')).read_bytes();mask=(E/'final'/(name+'.mask')).read_bytes()
    assert len(rgba)==w*h*4 and len(mask)==w*h
    assert set(rgba[3::4])=={255};assert all(b==0 for b in mask)
    rgba_rgb=b''.join(rgba[i:i+3] for i in range(0,len(rgba),4));assert rgba_rgb==decoded['final']
    fm=lookup[name];assert (fm['width'],fm['height'],fm['rgbaBytes'],fm['maskBytes'],fm['unsupportedPixels'])==(w,h,len(rgba),len(mask),0)
    changes=sum(decoded['original'][i:i+3]!=decoded['final'][i:i+3] for i in range(0,len(rgba_rgb),3))
    records.update(name=name,rgbaByteCount=len(rgba),rgbaSHA256=sha(E/'final'/(name+'.rgba')),alphaValues=sorted(set(rgba[3::4])),maskByteCount=len(mask),maskSHA256=sha(E/'final'/(name+'.mask')),maskValues=sorted(set(mask)),unsupportedPixels=sum(b!=0 for b in mask),changedPixels=changes,ppmByteIdentical=(E/'original'/(name+'.ppm')).read_bytes()==(E/'final'/(name+'.ppm')).read_bytes(),sceneByteIdentical=(E/'original'/(name+'.json')).read_bytes()==(E/'final'/(name+'.json')).read_bytes(),pngRGBEqualsPPM=True,rawRGBEqualsPPM=True)
    assert changes==0 and records['ppmByteIdentical'] and records['sceneByteIdentical'];results.append(records)
manifest=json.loads((E/'final-source-manifest.json').read_text());bindings={p:sha(ROOT/p)==s for p,s in manifest['sourceSHA256'].items() if p.startswith('Sources/LightingCore/')}
assert len(bindings)==31 and all(bindings.values())
report={'actualAgent':'/root/wave08/w72_geometry','parent':'/root/wave08','inputCommit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'privateTree':str(ROOT),'privateOutput':str(OUT),'host':platform.platform(),'python':sys.version.split()[0],'command':'python3 /tmp/keyfill03-7f4b/builds/W72-geometry/W72-verify.py','all31LightingCoreHashesMatchFinalManifest':bindings,'sourceManifestSHA256':sha(E/'final-source-manifest.json'),'contacts':{stage:png(E/(stage+'-contact.png'),False)[0] for stage in ['original','final']},'fixtures':results,'aggregate':{'fixtures':len(results),'changedPixels':sum(r['changedPixels'] for r in results),'unsupportedPixels':sum(r['unsupportedPixels'] for r in results),'finalRGBAPixels':sum(r['maskByteCount'] for r in results)},'result':'PASS archived data consistency only','limits':['No render, build, benchmark, native/Metal/device execution performed by W72.','Original raw RGBA and masks are not archived; original opacity and unsupported counts remain manifest claims, not direct-byte checks.','Exact token counters unavailable; 12000 working target, no exact 60-percent checkpoint asserted.']}
(OUT/'W72-parser-receipt.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['actualAgent','inputCommit','aggregate','contacts','result']},indent=2))
