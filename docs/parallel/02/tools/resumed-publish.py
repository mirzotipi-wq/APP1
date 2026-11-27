import sys,pathlib,subprocess,json
r=pathlib.Path('/tmp/keyfill02-r2');base=sys.argv[1];out=pathlib.Path('/tmp/keyfill02-r2-publish');out.mkdir(exist_ok=True)
def git(*a):return subprocess.check_output(['git','-C',str(r),*a],text=True)
names=git('diff','--name-only',base,'HEAD').splitlines();entries=[];batches=[]
for name in names:
 content=git('show','HEAD:'+name);mode=git('ls-tree','HEAD',name).split()[0];item={'path':name,'mode':mode,'type':'blob','content':content}
 if entries and len(json.dumps(entries+[item]))>70000:batches.append(entries);entries=[]
 entries.append(item)
if entries:batches.append(entries)
for i,items in enumerate(batches):(out/f'{i}.json').write_text(json.dumps(items))
print(json.dumps(dict(base=base,tree=git('rev-parse',base+'^{tree}').strip(),message=git('log','-1','--pretty=%B').strip(),batches=len(batches))))
