"""Model-only branch check; does not execute Swift, UIKit, SceneKit, or RealityKit."""
import hashlib
import json
import pathlib
import subprocess

OUT = pathlib.Path(__file__).parent
REPO = "/tmp/keyfill05-be879deb/repo"
SHA = "9725fb1177a5c7afbdf798ffd627e65e604c75b1"
PATHS = [
    "App/RealityStudioPreview.swift", "App/SpatialPreview.swift",
    "App/SpatialViewportGeometry.swift", "NativeTests/SpatialPreviewTests.swift",
    "NativeTests/SpatialInteractionTests.swift", "NativeTests/SpatialViewportStateTests.swift",
    "NativeTests/SpatialEntityUpdateTests.swift",
]
sources = {}
commands = []
for path in PATHS:
    command = ["git", "show", f"{SHA}:{path}"]
    sources[path] = subprocess.check_output(command, cwd=REPO)
    commands.append({"argv": command, "exit": 0})

class Model:
    def __init__(self, conditional):
        self.conditional = conditional
        self.mode = None
        self.fit = None
        self.pov = None
        self.lens = None
        self.available = False

    def update(self, valid, camera, request, framing=True):
        needs_fit = not camera and (self.mode != camera or self.fit != request)
        if valid or not self.conditional:
            self.mode = camera
        self.available = valid and (not camera or framing)
        if not valid:
            return self.snapshot(needs_fit)
        if camera:
            self.pov = "authored" if framing else None
            if framing:
                self.lens = "authored"
        elif needs_fit:
            self.pov = "orbit"
            self.lens = 48
            self.fit = request
        self.mode = camera
        return self.snapshot(needs_fit)

    def snapshot(self, needs_fit):
        return dict(mode=self.mode, fit=self.fit, pov=self.pov, lens=self.lens,
                    available=self.available, needs_fit=needs_fit)

results = []
for conditional in [False, True]:
    for framing in [True, False]:
        model = Model(conditional)
        inputs = [(True, False, 0, True), (True, True, 0, framing),
                  (False, False, 0, True), (True, False, 0, True)]
        trace = [model.update(*item) for item in inputs]
        expected = "orbit" if conditional else ("authored" if framing else None)
        assert trace[-1]["pov"] == expected
        results.append(dict(conditional_valid_mode=conditional,
                            camera_framing=framing, trace=trace))
    model = Model(conditional)
    model.update(True, False, 0)
    model.pov = "user orbit"
    model.update(False, False, 0)
    recovered = model.update(True, False, 0)
    assert recovered["pov"] == "user orbit"

spatial = sources["App/SpatialPreview.swift"].decode()
assert spatial.index("coordinator.lastCameraMode = cameraMode") < spatial.index("guard valid else")
assert "let needsFit = !cameraMode && (modeChanged || coordinator.lastFitRequest != fitRequest)" in spatial
evidence = dict(canonicalID="/root/w04_acceptance/concurrency", inputSHA=SHA,
                kind="model-only; not native execution", commands=commands,
                sha256={p: hashlib.sha256(b).hexdigest() for p, b in sources.items()},
                results=results, outcome="Four mode-transition and two same-mode checks matched source-derived expectations",
                source_edits=[], commits=[], limits="Model abstracts geometry and UIKit dispatch; no native, build, renderer, device, or VoiceOver execution")
target = OUT / "evidence.json"
target.write_text(json.dumps(evidence, indent=2) + "\n")
print(evidence["outcome"])
for path in [OUT / "report.md", OUT / "model_check.py", target]:
    print(hashlib.sha256(path.read_bytes()).hexdigest(), path.name)
