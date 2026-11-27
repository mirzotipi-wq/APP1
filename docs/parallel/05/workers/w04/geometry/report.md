# Wave 04 geometry review

Agent: `/root/w04_acceptance/geometry`  
Input SHA: `956a3b1d70cb3d67ba136821d9828be80aee1c3b`

## Result

No Fit containment or clipping defect identified for equipment within the reviewed limits. Floor/grid are deliberately excluded. Bounds include rotated 4 m housings, selection margins, aim markers and world-floor stand bases; entity dimensions agree with those margins.

The independent scalar witness found:

- Arbitrary housing offset <=2.874770 m; every equipment coordinate fits +/-102.874770 m. Bounds radius <=178.184328 m, so Fit distance <=490.652737 m, below its 1,500 m cap.
- Sphere-fit near depth >=1.402900 m versus near=0.02 m. For targets bounded to +/-300 m, target-to-equipment distance <=697.799570 m, leaving >=52.200430 m within `far=distance+750` at any orbit angle.
- Extreme-pan witness: target=(300,300,-300), distance=0.45 m, opposite authored point=(-100,-100,100): depth=693.270323 m < far=750.45 m.
- Three boxes, eight corners and four layouts produced 96 passing projection checks, including Float-rounded vertical FOVs. The 100 m stand / coincident 4 m modifier had depth=121.324908...159.856738 m < far=890.590823 m. Maximum absolute normalized screen coordinate: 0.874857551 <1.

Source review: ordinary updates/layout preserve orbit; initial/changed Fit tokens recenter. Pan uses the smaller viewport axis and preserves distance. Matching regressions cover translation, high stands, extreme rigs, gesture bounds, Fit recovery and clipping; they were not executed.

## Commands and evidence

Successful pinned `git show` reads covered AGENTS, architecture/design/acceptance, geometry/entities/adapters, core limits/frame/bounds and native tests. Exact inputs are in `commands.txt`.

`python3 /tmp/keyfill05-be879deb/waves/w04/geometry/witness.py --reviewed-only` exited 0; results are in `witness.json`. Initial invocation exited 1 after git exited 128 because executor reset removed the repo. Calculation uses already-reviewed constants; no post-reset source recheck or source hashes.

## Limits and changes

Python derivation only. No Swift build, XCTest, native rendering, screenshot, device, VoiceOver or performance evidence; no previous CI carried forward. Source changes/commits: **none**. Artifacts: this report, `witness.py`, `witness.json`, `commands.txt`.
