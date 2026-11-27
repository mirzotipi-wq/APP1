# Wave08 current execution update

This addendum supersedes pending-execution language in earlier wave08 reports without rewriting those reports' observations.

Root's exact receipt at `docs/parallel/05/validation/NATIVE-4e694bc.md` records source `4e694bc377c4825d1d2dd52fcd7900e534c75072`, workflow45838950713, job139980771221 as successful: **184/184 native methods, including38/38 spatial**, one ordered start/pass each, zero failures/skips/duplicates/omissions. Debug test-bundle and unsigned Release builds passed. Core job139978271046 passed366Debug/366Release methods and100tooling checks. Native raw-log SHA256 is `b538e299ef327f66ae9307d1f8c590bc178ff5782fafd6b04e801668961281ed`.

Actual runtime is x86_64 iPhone17Pro simulator, iOS26.5, Xcode26.6. Ten spatial methods exercise Swift helper/state arithmetic;28 directly exercise SceneKit behavior. The eight later navigation/selection/aim-recovery methods are now executed at their correct source. RealityKit construction is bypassed on this runtime.

Fresh original ordinary/crowded captures are described in `docs/parallel/05/captures/receipt-4e694bc.json`: artifact15133365346, ZIP SHA256 `9ae832b001ec38c9f5cd5a316835d3c1036430ed832b7ddd1f563c15e02cc79f`. Their SHA256 values match the9725 originals exactly. The interactions role records its own visual inspection and scope.

The private Float-FOV candidate `a92b4fdc5bb8d3af75b3557949477a730462e000` changes one App helper and adds one state method, producing a185native/39spatial candidate inventory. Its independent source/scalar approval does not transfer the4e native pass to changed source. Root published the correction at60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a, with the private tree preserved asa69f6252e85123ae34e7ef7336fb12794529c80b. At15:48:28UTC root reported newrun45851365897 core job140020330561 successful and simulator job140022794410 queued. Candidate native execution remains pending.

Prior4e final jobs passed core/native/optics/room/export; library/accessibility/visual-review were cancelled by the successor after native completed. These dispositions supersede earlier running observations and do not establish a full UI or M03 pass. Root owns subsequent CI and receipt updates; this packet does not promote M03 or release status.

