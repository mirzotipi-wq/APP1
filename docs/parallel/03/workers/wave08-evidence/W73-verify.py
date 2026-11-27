#!/usr/bin/env python3
"""Bounded saved-artifact audit; does not render, compile, benchmark, or write images."""
import datetime, hashlib, importlib.util, io, json, pathlib, platform, struct, subprocess, sys, traceback, zlib
ROOT = pathlib.Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
TREE = pathlib.Path('/tmp/keyfill03-7f4b/workers/W73-api')
E = ROOT/'docs/parallel/03/evidence'
OUT = ROOT/'docs/parallel/03/workers/wave08-evidence'
INPUT = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
sha = lambda b: hashlib.sha256(b).hexdigest()
checks = []
def check(label, value):
    checks.append({'check': label, 'passed': bool(value)})
def run(args, cwd=TREE):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return {'command':args,'cwd':str(cwd),'exitCode':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
def png_info(data):
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos, chunks = 8, []
    while pos < len(data):
        n = int.from_bytes(data[pos:pos+4], 'big'); typ = data[pos+4:pos+8]
        payload = data[pos+8:pos+8+n]; crc = data[pos+8+n:pos+12+n]
        assert len(payload) == n and len(crc) == 4
        assert zlib.crc32(typ + payload) & 0xffffffff == int.from_bytes(crc,'big')
        chunks.append(typ.decode('ascii'))
        if typ == b'IHDR': ihdr = struct.unpack('>IIBBBBB', payload)
        pos += n+12
    assert pos == len(data) and chunks[0] == 'IHDR' and chunks[-1] == 'IEND'
    return {'width':ihdr[0],'height':ihdr[1],'bitDepth':ihdr[2],'colorType':ihdr[3], 'compression':ihdr[4],'filter':ihdr[5],'interlace':ihdr[6],'chunks':chunks,'chunkCRCsValid':True}
def main():
    receipt = {'actualAgent':'/root/wave08/w73_api','parent':'/root/wave08','input':INPUT,
        'tree':str(TREE),'privateOutput':'/tmp/keyfill03-7f4b/builds/W73-api',
        'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'host':platform.platform(),
        'python':sys.version,'scriptSHA256':sha(pathlib.Path(__file__).read_bytes()),
        'exactTokenCounters':'unavailable; 12k working target', 'checks':checks}
    receipt['git'] = run(['git','rev-parse','HEAD','HEAD^{tree}'])
    head, treehash = receipt['git']['stdout'].splitlines()
    check('immutable_input_head',head == INPUT)
    receipt['treeHash'] = treehash
    orig = json.loads((E/'original/manifest.json').read_text())
    final = json.loads((E/'final/manifest.json').read_text())
    comp = json.loads((E/'final-comparison.json').read_text())
    orig_by = {f['name']:f for f in orig['fixtures']}; final_by = {f['name']:f for f in final}; cmp_by = {f['name']:f for f in comp['fixtures']}
    check('12_unique_matching_fixture_names',len(orig_by) == len(orig['fixtures']) == len(final_by) == len(final) == len(cmp_by) == 12 and orig_by.keys() == final_by.keys() == cmp_by.keys())
    receipt['manifestSHA256'] = {n:sha((E/n).read_bytes()) for n in ['original/manifest.json','final/manifest.json','final-comparison.json','final-source-manifest.json','baseline.json']}
    receipt['manifestSchemas'] = {'original':'schemaVersion=1 object; 12 results and synthetic provenance','final':'12-result array; originalScene, opaque, validMask, byte counts','sameBytes':(E/'original/manifest.json').read_bytes()==(E/'final/manifest.json').read_bytes(),'finalSceneHandling':'source copies original sceneData bytes; scene equality is preservation, not independent re-encoding'}
    pil = importlib.util.find_spec('PIL') is not None
    if pil:
        import PIL
        from PIL import Image
        receipt['PNGDecoder'] = {'library':'Pillow','version':PIL.__version__,'role':'saved PNG RGB verification only; no PNG re-encoding'}
    else: receipt['PNGDecoder'] = {'available':False,'decode':'unrun; W72 independent parser receipt remains separate evidence'}
    rows = []
    for name, f in final_by.items():
        o, c = orig_by[name], cmp_by[name]
        w,h = f['width'],f['height']; n=w*h
        row = {'name':name,'dimensions':[w,h],'hashes':{},'equalOriginalBytes':{}}
        blobs = {}
        for ext in ['ppm','png','json','rgba','mask']:
            p=E/'final'/f'{name}.{ext}'; b=p.read_bytes(); blobs[ext]=b; row['hashes'][p.name]=sha(b)
            check(f'{name}: final {ext} stored comparison hash',sha(b)==c['hashes'][p.name])
            if ext in ['ppm','png','json']:
                ob=(E/'original'/p.name).read_bytes()
                row['equalOriginalBytes'][ext]=ob==b
                check(f'{name}: original {ext} comparison hash',sha(ob)==c[f'original_{ext}_sha256'])
                check(f'{name}: final-original {ext} bytes',ob==b)
        ppm = blobs['ppm']; header = f'P6\n{w} {h}\n255\n'.encode()
        check(f'{name}: P6 framing and payload',ppm.startswith(header) and len(ppm)==len(header)+n*3)
        rgb=ppm[len(header):]; rgba=blobs['rgba']; mask=blobs['mask']
        projected=bytearray(n*3)
        for channel in range(3): projected[channel::3]=rgba[channel::4]
        row['rawRGBAtoPPMRGBEqual']=bytes(projected)==rgb
        row['alphaValues']=sorted(set(rgba[3::4]));row['maskValues']=sorted(set(mask))
        row['rgbaBytes']=len(rgba);row['maskBytes']=len(mask)
        check(f'{name}: RGBA RGB projection',row['rawRGBAtoPPMRGBEqual'])
        check(f'{name}: RGBA opaque and counts',len(rgba)==n*4==f['rgbaBytes']==o['rgbaByteCount'] and row['alphaValues']==[255] and f['opaque'])
        check(f'{name}: mask zero and counts',len(mask)==n==f['maskBytes']==o['unsupportedMaskByteCount'] and row['maskValues']==[0] and f['unsupportedPixels']==o['unsupportedPixels']==0 and f['validMask'])
        check(f'{name}: scene and manifest association',o['sceneFile']==f['originalScene']==name+'.json' and o['ppmFile']==name+'.ppm' and o['width']==o['expectedWidth']==w and o['height']==o['expectedHeight']==h and o['subject']==f['subject'] and o['passed'] and not o['validationErrors'])
        scene=json.loads(blobs['json'])
        row['sceneLightIDs']=[l['id'] for l in scene['lights']]
        check(f'{name}: fixture IDs fixed',all(x in ['00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000003'] for x in row['sceneLightIDs']))
        row['PNG']=png_info(blobs['png'])
        check(f'{name}: PNG RGB8 and dimensions',row['PNG']['width']==w and row['PNG']['height']==h and row['PNG']['bitDepth']==8 and row['PNG']['colorType']==2 and row['PNG']['chunks']==['IHDR','IDAT','IEND'])
        if pil:
            im=Image.open(io.BytesIO(blobs['png'])); im.load()
            row['PNG']['decodedMode']=im.mode;row['PNG']['decodedRGBEqualsPPM']=im.mode=='RGB' and im.tobytes()==rgb
            check(f'{name}: decoded PNG RGB equals PPM',row['PNG']['decodedRGBEqualsPPM'])
        row['originalRawRGBAExists']=(E/'original'/f'{name}.rgba').exists();row['originalRawMaskExists']=(E/'original'/f'{name}.mask').exists()
        rows.append(row)
    receipt['fixtures']=rows
    baseline=json.loads((E/'baseline.json').read_text())
    receipt['baselineOriginalHashes']={p:sha((E/p).read_bytes())==h for p,h in baseline['originalSHA256'].items()}
    check('all 25 baseline original artifact hashes match',len(receipt['baselineOriginalHashes'])==25 and all(receipt['baselineOriginalHashes'].values()))
    sm=json.loads((E/'final-source-manifest.json').read_text())
    src=[]
    for p, expected in sm['sourceSHA256'].items():
        actual=sha((TREE/p).read_bytes())
        src.append({'path':p,'expectedSHA256':expected,'actualSHA256':actual,'matches':expected==actual})
    receipt['finalSourceManifestMatches']=src
    core=[r for r in src if r['path'].startswith('Sources/LightingCore/')]
    check('31 LightingCore source hashes match final source manifest',len(core)==31 and all(r['matches'] for r in core))
    receipt['sourceMismatches']=[r['path'] for r in src if not r['matches']]
    receipt['reviewedSources']={p:sha((TREE/p).read_bytes()) for p in ['scripts/render-study-fixtures.swift','docs/parallel/03/evidence/final-matrix-probe.swift','Sources/LightingCore/ReferencePNG.swift']}
    receipt['sourceTextSearch']=run(['rg','-n','ReferencePNG.metadataFree|pngData\\(|CGImageDestination','App','Sources'])
    receipt['conversionProvenanceSearch']=run(['rg','-n','-g','*.md','-g','*.json','-g','*.py','-g','*.sh','PIL|Pillow|Image\\.open|PPM.to.PNG|PNG conversion|png conversion|png.*convert|convert.*png','docs/parallel/03','scripts'],ROOT)
    receipt['limits']=[
      'Saved final/original PNG, PPM and scene equality is observed on these exact 12 artifacts, not an arbitrary encoder/platform/toolchain guarantee.',
      'Scene equality is direct byte preservation in final-matrix-probe.swift; original/final manifests intentionally use different schemas.',
      'PNG is RGB8 (color type 2), not the raw RGBA8 archive. Final alpha and masks are separately verified; absent original raw files prevent byte comparison.',
      'ReferencePNG preserves retained chunks/CRCs from already encoded input. It does not generate renderer PNG, decode pixels, validate CRCs, or canonicalize alternate encoders.',
      'Fixture writer uses fixed IDs, sorted-key JSON, deterministic P6 packing; source reproducibility comment requires unchanged renderer and toolchain.',
      'Hash/provenance checks do not rerun original execution; carried-forward final render receipt declares Swift6.2.1 -O and exact optimized LightingCore objects.',
      'No rerender, rebenchmark, build, Swift/native/Metal/device test, or physical calibration performed by W73.'
    ]
    receipt['status']='pass' if all(c['passed'] for c in checks) else 'failed'
    receipt['checkCount']=len(checks); receipt['failedChecks']=[c['check'] for c in checks if not c['passed']]
    (OUT/'W73-byte-provenance.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps({'status':receipt['status'],'checks':len(checks),'failed':receipt['failedChecks'],'sourceMismatches':receipt['sourceMismatches'],'sourceHashes':receipt['reviewedSources'],'PNGDecoder':receipt['PNGDecoder'],'manifestHashes':receipt['manifestSHA256'],'conversionSearch':receipt['conversionProvenanceSearch'],'sanitizerConsumerSearch':receipt['sourceTextSearch']},indent=2))
    return receipt
try:
    result=main()
except BaseException:
    failure={'actualAgent':'/root/wave08/w73_api','status':'exception','traceback':traceback.format_exc(),'completedChecks':checks}
    (OUT/'W73-verification-failure.json').write_text(json.dumps(failure,indent=2)+'\n')
    raise
