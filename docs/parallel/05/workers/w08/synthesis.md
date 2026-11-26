# Wave08 synthesis — spatial envelope and acceptance review

## Outcome and source identity

Wave08 reviews frozen source `4e694bc377c4825d1d2dd52fcd7900e534c75072` against campaign baseline `f150f98e35dd735927075aac4d2f8b02295c6a67`. The bounded review found no represented-equipment envelope omission and one precise extreme-aspect Float projection defect. That defect has a minimal independently approved correction, published by root at `60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a`. Private writer commit `a92b4fdc5bb8d3af75b3557949477a730462e000` is preserved remotely as `a69f6252e85123ae34e7ef7336fb12794529c80b`; both exact candidate files and patch are retained here.

Source4e's native receipt verifies **184 native / 38 spatial passes**, Debug test-bundle and Release builds. The published correction has **185 native / 39 spatial declarations**; at15:48:28UTC root reported run45851365897 core job140020330561 successful and simulator job140022794410 queued. No185/39native pass is claimed. No4e pass is transferred to changed source. `acceptance/current_execution_update.md` and timestamped `acceptance/ci_observations.json` supersede pending wording in earlier reports while preserving their original observations. Root owns subsequent CI results and final milestone accounting.

## Geometry and framing

The case matrix covers ordinary, translated `(80,0,75)`, coincident four-meter modifier, empty/sparse, tall-stand, twelve-light crowded, and narrow/wide scenes. Core bounds retain authored centers, targets and defined emitting faces. App bounds add actual housings, selection outlines, busts, camera bodies/lenses, floor-anchored stands and aim-marker volume. Floor/grid are deliberately outside the equipment-Fit contract.

The geometry role derives complete primitive envelopes. The implementation witness independently uses displayed-primitive support functions, separate from its helper transcription: spheres/ellipsoids, capsule/cylinder, boxes, all twelve thick RealityKit outline edges and a conservative enclosing aim tube. It checks15 scenes/760 primitive instances and240 full-volume frustum half-space cases per projection model, with zero envelope/practical-projection failures and minimum plane clearance0.321782484m. The analytical ideal sphere radius subtends at most21.294250° against the minimum24° viewport half-angle; the1500m clamp cannot truncate a valid fitted rig. Arbitrary valid rigid emitter/camera orientations preserve the envelope inclusions; the numerical fixture matrix is bounded, not an exhaustive native sweep.

These calculations use ideal geometry and camera bases. The second projection model accounts for Float degree quantization only. Native quaternion conversion, camera-matrix construction, Float trigonometry, mesh tessellation/rasterization and renderer culling remain outside the portable witness.

## Concrete defect and correction

For an empty scene with subject `(-100,1.5,0)` and camera `(100,1.5,0)`, viewport `0.0001×3000` produced ideal vertical FOV179.99999142077152°. Nearest Float179.99998474121094° passed the old `<180` guard, but implied only14.0539879075° horizontal half-angle; the camera-marker center reached20.5348345076°, normalized x≈1.49634. This is a source/scalar counterexample at an extreme subpixel layout, not an observed practical clipping frame.

The correction chooses the smallest representable Float angle at least as wide as the ideal angle, advancing by one Float ULP only when nearest rounding narrowed it. It rejects an enclosing180° angle and returns the representable value as Double. One focused state regression covers six accepted and two rejected layouts. The independent reviewer reproduced the old failures, checked practical and stressed accepted controls, confirmed the sole caller handles nil, and approved the exact two-file patch. No arbitrary viewport cutoff, Core change, gesture change or acceptance-threshold change was added.

## State, topology and usability

Ordinary scene, selection, callback and aspect changes preserve a retained adapter's viewpoint. Explicit Fit and entering Orbit intentionally fit; recreating a coordinator is a separate boundary. Invalid scene updates discard stale equipment ownership while preserving pending mode/Fit state. Current graph ancestry and live UUID checks reject removed/reintroduced hit identities. The first-save wrapper `.id(generation)` issue remains with lane01.

For twelve elevated fixtures, source topology gives SceneKit41 direct content children/54 descendants, and RealityKit341 graph entities including its anchor plus two orbit-camera entities. Stable UUIDs retain lamp objects. The RealityKit seven-light shading cap applies to eligible emission components; all twelve authored fixtures remain represented and selectable. These are bounded source/identity findings, not measured memory, FPS or leak results.

The interactions role actually viewed all four original ordinary/crowded PNGs at9725 and4e and verified receipt hashes and byte identity. The two fitted rigs have viewport margins. Crowded foreground panels obscure the torso and other equipment; the selected right rectangle's outline is visible. The ordinary selected point mainly reads as a yellow spot. Camera direction, dark floor and thin stands remain weak visually. Captures are SCNView snapshots in UIWindow during XCTest, with no delivered gesture or full-app host.

Normal native view accessibility trees hide implementation geometry. The external Lights list supplies named buttons, selected traits/checkmarks and guarded actions. Unavailable feedback supports Dynamic Type, but source review does not establish maximum-text visibility/contrast in the fixed280-point clipped viewport. RealityKit uses a non-AR surface without automatic camera-session configuration. No manual VoiceOver,44-point3D-target, whole-app privacy, device or RealityKit-runtime pass is inferred.

## Evidence boundaries and integration

Actual4e runtime is x86_64 iPhone17Pro simulator/iOS26.5/Xcode26.6, which selects SceneKit before constructing RealityKit. Native helper arithmetic and direct SceneKit projection/identity assertions remain distinct from portable proofs and actual gesture delivery. The platform report independently reconciles184ordered start/pass pairs,38spatial methods and26discrete native projectPoint samples. Prior4e final jobs passed core/native/optics/room/export; library/accessibility/visual-review jobs were cancelled by the successor after native completed. Those cancellations do not become UI or milestone passes.

The final ledger contains exactly the acceptance lead and nine actual fresh `fork_turns:none` children, with ten complete reports. One independent context supplied early source approval, was paused while other roles ran, and resumed for final packet review; it is counted once. The independent reviewer verified all nine other report hashes, challenged the synthesis and ledger, and approved the bounded packet. All reports and supporting artifacts are retained with exact hashes. Root verified the230 outside-lane changed paths as inherited from main9e0e2ba; this wave authors no outside-lane changes. No milestone/release status is promoted.

