#!/usr/bin/env python3
"""Read-only lifecycle review inventory; does not run Swift or native tests."""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


def git_blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--worktree", type=Path, required=True)
    parser.add_argument("--renderer", type=Path, required=True)
    parser.add_argument("--tests", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    records = []

    def run(argv):
        result = subprocess.run(argv, cwd=args.worktree, text=True, capture_output=True, check=False)
        records.append(dict(argv=argv, cwd=str(args.worktree), exit_code=result.returncode,
                            stdout=result.stdout, stderr=result.stderr))
        return result

    baseline = run(["git", "rev-parse", "HEAD"]).stdout.strip()
    run(["git", "status", "--short", "--branch"])
    run(["git", "log", "-5", "--oneline"])
    run(["python3", "scripts/agent_cycle.py", "check"])
    run(["python3", "scripts/agent_cycle.py", "next"])
    docs = ["AGENTS.md", "agents/OPERATING_PROTOCOL.md", "agents/HANDOFF.md", "agents/state.json",
            "docs/PRODUCT.md", "docs/ARCHITECTURE.md", "docs/ROADMAP.md", "docs/QUALITY.md",
            "docs/DESIGN.md", "docs/acceptance/m02-m03-code.md"]
    startup = {name: git_blob((args.worktree / name).read_bytes()) for name in docs}
    sources = {
        "frozen_renderer": args.renderer,
        "frozen_tests": args.tests,
        "base_renderer": args.worktree / "App/MetalStudyRenderer.swift",
        "base_tests": args.worktree / "NativeTests/StudyRenderCacheTests.swift",
        "cache": args.worktree / "Sources/LightingCore/StudyFrameCache.swift",
        "image_contract": args.worktree / "Sources/LightingCore/ReferenceStudy.swift",
        "eligibility": args.worktree / "Sources/LightingCore/StudyFloat32Eligibility.swift",
    }
    hashes = {key: dict(path=str(path), git_blob=git_blob(path.read_bytes()))
              for key, path in sources.items()}
    assert hashes["frozen_renderer"]["git_blob"] == "98aa3c619ef05b7cc1369ecab71a1b04456a89d3"
    assert hashes["frozen_tests"]["git_blob"] == "2af764b51023dc66a9cc0070d8d49f5bd7de334e"
    # Match repository scripts/native_test_shards.py discovery, including inline declarations.
    pattern = re.compile(r"\bfunc\s+(test\w*)\s*\(")
    superseded_pattern = re.compile(r"^\s*func\s+(test\w+)\s*\(", re.MULTILINE)
    before = sources["base_tests"].read_text()
    after = sources["frozen_tests"].read_text()
    old_methods, new_methods = pattern.findall(before), pattern.findall(after)
    original_prefix = sources["base_tests"].read_bytes().rsplit(b"\n}", 1)[0]
    prefix_preserved = sources["frozen_tests"].read_bytes().startswith(original_prefix)
    assert prefix_preserved
    inventory = {str(path.relative_to(args.worktree)): pattern.findall(path.read_text())
                 for path in sorted((args.worktree / "NativeTests").rglob("*.swift"))}
    count_before = sum(map(len, inventory.values()))
    count_candidate = count_before - len(old_methods) + len(new_methods)
    omitted = {str(path.relative_to(args.worktree)):
               [name for name in pattern.findall(path.read_text())
                if name not in superseded_pattern.findall(path.read_text())]
               for path in sorted((args.worktree / "NativeTests").rglob("*.swift"))}
    omitted = {path: names for path, names in omitted.items() if names}
    assert count_before == 160 and count_candidate == 168
    renderer_diff = run(["git", "diff", "--no-index", "App/MetalStudyRenderer.swift", str(args.renderer)])
    tests_diff = run(["git", "diff", "--no-index", "NativeTests/StudyRenderCacheTests.swift", str(args.tests)])
    assert renderer_diff.returncode == 1 and tests_diff.returncode == 1
    run(["git", "status", "--short", "--branch"])
    summary = dict(
        identity="w042 /root/w041/w042", role="lifecycle-invariants reviewer", wave=5, lane="04",
        scope="finish/04-metal-cache; report and evidence only", base=baseline,
        executed="Python read-only inventory, git/source reads, agent_cycle check and next; no Swift execution",
        invocation=[sys.executable, *sys.argv],
        startup_documents=startup, reviewed_sources=hashes,
        method_inventory=dict(base_cache_methods=len(old_methods), candidate_cache_methods=len(new_methods),
                              original_prefix_byte_preserved=prefix_preserved,
                              additions=[name for name in new_methods if name not in old_methods],
                              base_native_declarations=count_before,
                              candidate_native_declarations=count_candidate,
                              counting_regex=pattern.pattern,
                              superseded_diagnostic=dict(regex=superseded_pattern.pattern,
                                                         base_count=156, candidate_count=164,
                                                         cause="Line anchor omitted inline declarations; not missing candidate source",
                                                         omitted_methods=omitted),
                              base_files=inventory),
        static_observations=[
            {"invariant": "ordinary cancellation never downgrades", "renderer_lines": "253-256,271-273",
             "test_lines": "494-520,559-597", "result": "source consistent; native methods unrun"},
            {"invariant": "confirmed failure evicts Metal before concurrent cancellation", "renderer_lines": "112-113,253-265,271-283,289-294",
             "test_lines": "454-490,600-635", "result": "source consistent; startup cache begins empty"},
            {"invariant": "precision rejection is per request", "renderer_lines": "245-246,258-259,275-277,283-286",
             "test_lines": "523-556,638-665,668-705", "result": "later uncached key distinguishes retryable backend"},
            {"invariant": "failed/cancelled frames never retained", "renderer_lines": "232-233,240-241,269-270,283-286,296-302",
             "test_lines": "274-318,454-555", "result": "guarded synchronous admission; post-check scheduling remains caller adoption concern"},
            {"invariant": "scene errors propagate", "renderer_lines": "253-256,271-273,284",
             "test_lines": "559-578,679-685", "result": "startup matrix; established-backend non-cancellation scene errors source-reviewed only"},
        ],
        limitations=["No Swift builds, native/UI/Metal tests, benchmarks or host kernel runs executed.",
                     "Scripted backend lifetime counters establish no GPU resource-release measurement.",
                     "CPU-cache preservation through startup failure is outside this assigned pass.",
                     "Three reported environment resets have no inferred cause.",
                     "agent_cycle check validates structure; next reports broader M03, not authority to expand 04 scope."],
        commands=records,
    )
    args.output.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"output": str(args.output), "base": baseline,
                      "original_cache_methods": len(old_methods), "new_cache_methods": len(new_methods) - len(old_methods),
                      "original_prefix_preserved": prefix_preserved,
                      "candidate_native_declarations": count_candidate,
                      "diagnostic_exit_codes": [r["exit_code"] for r in records if r["argv"][0] == "python3"]}, indent=2))


if __name__ == "__main__":
    main()
