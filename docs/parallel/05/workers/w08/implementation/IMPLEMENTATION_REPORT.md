# Wave 08 implementation

Canonical ID: `/root/w08_acceptance/implementation`
Status: `completed_portable_witness_and_source_review`
Input SHA: `4e694bc377c4825d1d2dd52fcd7900e534c75072`
Baseline: `f150f98e35dd735927075aac4d2f8b02295c6a67`
Detached candidate: `a92b4fdc5bb8d3af75b3557949477a730462e000`

The portable witness passed 15 scenes/760 primitive instances and 240 whole-volume frustum checks per model. Maximum envelope excess: zero; minimum practical clearance: 0.321782484 m. Coverage includes ordinary, translated X80/Z75 and Y75, coincident 4 m, empty/sparse, tall stand, twelve lights, arbitrary aim/roll/camera orientations, and narrow/wide layouts.

Independent primitive support functions include bust/camera volumes, selection thickness, aim tube and floor-anchored stands. The ideal sphere proof bounds angular radius at 21.294250° against the minimum 24° half-angle, with near/far clearance. Full assumptions and primitive dimensions are in geometry_envelope_notes.md.

Original counterexample retained: empty scene, subject (−100,1.5,0), camera (100,1.5,0), viewport 0.0001×3000. Double FOV 179.99999142077152° rounds to accepted Float 179.99998474121094°; horizontal half-angle 14.053987907538744° excludes the marker center at 20.534834507590055° (normalized X 1.4963415439584467).

The two-file candidate rounds outward by at most one Float ULP, rejecting 180°. Its one focused new native regression remains unrun. No builds/native methods ran here; original 38 source spatial methods and historical 30 passes remain distinct. Float-angle-only calculations are not native projection or telemetry.

Artifacts under `/tmp/keyfill05-be879deb/waves/w08/implementation/`:

| File | SHA256 |
| --- | --- |
| portable_geometry_witness.py | 96cda16eed0d150b1494a903b88fc450859f1c71b544731491e183414988c348 |
| portable_geometry_witness.json | d5c4a9f64b59ef329cf35985309a8906aaabf7c3cb111258902b039f2a65128b |
| float_fov_candidate.patch | 8fdf2042441591771b1a19b109a2e600758f461bdfb5f33599079991ea77dcbe |
| artifact_manifest.json | 9b3028a957808af9f42094ea022c6a1a293c7612091aa86f58916692659787e4 |

Exact witness command:
```sh
python3 /tmp/keyfill05-be879deb/waves/w08/implementation/portable_geometry_witness.py --repo /tmp/keyfill05-be879deb/waves/w08/implementation/worktree --output /tmp/keyfill05-be879deb/waves/w08/implementation/portable_geometry_witness.json
```

`git diff --check` passed. Manifest records remaining commands, notes and full candidate-source paths/hashes. Full witness, JSON, patch, source/test and report are retained in functions.store. No cleanup performed.

