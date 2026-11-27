#!/usr/bin/env python3
"""Create one detached sparse worker worktree; requires a working local Git host."""
import argparse, pathlib, subprocess
p = argparse.ArgumentParser()
p.add_argument("repository", type=pathlib.Path)
p.add_argument("workspace_root", type=pathlib.Path)
p.add_argument("worker_name")
p.add_argument("revision")
a = p.parse_args()
if not a.worker_name.replace("-", "").replace("_", "").isalnum():
    raise SystemExit("Use a simple unique worker name")
repo = a.repository.resolve()
work = a.workspace_root.resolve() / a.worker_name
if work.exists():
    raise SystemExit("Worker path exists; preserve it and choose a new path")
def git(*args):
    subprocess.run(["git", "-C", str(repo), *args], check=True)
git("config", "extensions.worktreeConfig", "true")
git("worktree", "add", "--detach", "--no-checkout", str(work), a.revision)
patterns = ["/Sources/", "/Tests/", "/Package.swift", "/AGENTS.md",
            "/agents/*.md", "/agents/state.json", "/docs/*.md",
            "/docs/acceptance/", "/docs/parallel/02/"]
subprocess.run(["git", "-C", str(work), "sparse-checkout", "set",
                "--no-cone", *patterns], check=True)
subprocess.run(["git", "-C", str(work), "checkout", "--detach", a.revision], check=True)
(work / "private-output").mkdir()
print(work)
