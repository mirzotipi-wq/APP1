from pathlib import Path
import hashlib
import subprocess

root = Path(__file__).resolve().parents[1]

def git(*args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True)

head = git("rev-parse", "HEAD").strip()
baseline = git("rev-parse", "f150f98").strip()
print("Fresh source trace executed after executor reset; not recovered original logs.")
print("command: python3 private-output/trace_source.py > private-output/source-trace.log")
print("worktree:", root)
print("source HEAD:", head)
print("comparison baseline:", baseline)
print("No Swift module, compiler, native GPU, or device execution used.")

files = {
    "Sources/LightingCore/SurfacePhotometry.swift": [(121, 133), (199, 219)],
    "Sources/LightingCore/ReferenceStudy.swift": [(4, 11), (248, 260), (270, 276), (304, 317), (326, 328), (354, 367), (423, 434), (548, 550)],
    "Sources/LightingCore/StudyFloat32Eligibility.swift": [(12, 29)],
    "App/MetalStudyRenderer.swift": [(36, 44), (212, 229)],
    "App/ReferenceStudy.metal": [(1, 12)],
    "App/StudyKernel.h": [(125, 147), (220, 241), (252, 266)],
}
for path, spans in files.items():
    current = git("show", f"{head}:{path}")
    old = git("show", f"{baseline}:{path}")
    print(f"\nFILE {path}\nsha256={hashlib.sha256(current.encode()).hexdigest()}")
    print("whole_file_unchanged_since_baseline:", current == old)
    if path.endswith("SurfacePhotometry.swift"):
        marker = "    private static func fullRectangleMidpoint("
        print("fullRectangleMidpoint_tail_exactly_unchanged:", current[current.index(marker):] == old[old.index(marker):])
        print("exact_surface_diff:")
        print(git("diff", baseline, head, "--", path))
    lines = current.splitlines()
    for start, stop in spans:
        for index in range(start - 1, min(stop, len(lines))):
            print(f"{index + 1}: {lines[index]}")
print("\nNo production writes; source inspection only. Existing independent rendering and 1%/5% photometry gates remain required.")
