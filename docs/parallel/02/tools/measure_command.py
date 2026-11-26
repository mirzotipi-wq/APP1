#!/usr/bin/env python3
"""Run a bounded command and retain its actual output and host resource receipt."""
import json,pathlib,resource,subprocess,sys,time
log=pathlib.Path(sys.argv[1]);command=sys.argv[2:];start=time.perf_counter()
with log.open('w') as f:result=subprocess.run(command,stdout=f,stderr=subprocess.STDOUT)
u=resource.getrusage(resource.RUSAGE_CHILDREN)
receipt={'command':command,'exit_code':result.returncode,'wall_seconds_including_lock_wait':time.perf_counter()-start,'maximum_child_rss_KiB_Linux':u.ru_maxrss,'child_user_seconds':u.ru_utime,'child_system_seconds':u.ru_stime,'scope':'host process-tree diagnostic; not device RSS or total concurrent host memory'}
log.with_suffix('.receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt));sys.exit(result.returncode)
