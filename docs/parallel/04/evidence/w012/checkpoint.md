# w012 checkpoint — silhouette guard derivation

Baseline: `3d0e20616d0e771ad72161592c59105f591951c9`; product source baseline `f150f98`. No tracked file edits, branches, commits, or builds. Only assigned lane04 sources, camera/fixture source definitions, and existing eligibility tests inspected.

Camera aims at center, so for pixel offsets `px,py`, `q=px²+py²`, closest squared distance is `D²q/(1+q)` and tangent `q*=r²/(D²-r²)`. Monotonicity in `|px|` reduces a grid minimum to the two neighbors of the positive-x tangent per row, with adjacent columns included for Double index rounding. Python analytic run `w012-silhouette-analytic-001` checked this against exhaustive arithmetic on 52 camera/width combinations; largest minimum-distance difference `3.886e-16 m`.

A blanket margin `64*Float.ulpOfOne*D` catches the confirmed width24/focal161.27198111190464 case but rejects `.portrait()` at width192: minimum silhouette clearance `3.57368754983e-6 m`, margin `2.28881835938e-5 m`. `32εD` also rejects. Existing explicit eligibility expects portrait to pass. Five ordinary startup camera configurations pass at width48 and192 (near-field still rejected by existing light guard); distance19/focal200 precision camera would also be newly rejected at192 by64εD. Parent notified; no smaller multiplier chosen simply to preserve fixtures.

Next: derive component-aware roundoff enclosure, especially axis-aligned stable closest-point arithmetic; any normalization/device assumptions must remain explicit. Alternative remains broad O(height) guard with preservation limitation disclosed.

Existing baseline `.log/.json` is shared C++ Float32 versus independent C++ Double geometry, not shipped Swift or actual Metal. My run is Python analytic Double only; no renderer parity claim.
