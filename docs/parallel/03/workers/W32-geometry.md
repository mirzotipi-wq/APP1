# W32 geometry/data — confirmed near-plane guard gap

**Runtime:** /root/wave04/geometry. **Input:** ace9f2eba068bc31dd04bb2f1e2028af315d6bdb. **Private tree:** /tmp/keyfill03-7f4b/workers/W32-geometry.

**Finding:** a clipped head entry can be hidden by an internal, front-facing neck entry; the renderer accepts the frame. This is exposed interior geometry, beyond harmless off-frame clipping.

Root compiled the unchanged pinned Swift sources with Swift 6.2.1 Linux and -O, then executed my probe; session 17562 exited 0 with empty stderr. I independently inspected the retained JSON, reconciled counts, and verified source/output hashes. The exact root command and attribution are preserved in wave04-evidence/W32-review-receipt.json. Mandatory startup reads completed; initial detached tree was clean. Both agent_cycle.py check and next exited 0 (structure only; M03 remains outstanding).

## Actual checks and results

The probe visited all 2,048 oblique pose/lens combinations: 1,980 passed camera preconditions, 68 failed them, and 760,320 sampled pixels were examined in 2.940567 seconds without reaching the 45-second deadline. There were 673 poses with a clipped first surface: 651 exposed backfaces and 22 passed the geometric-facing guard. Zero sampled uncut views falsely rejected.

Eight candidates received 40 actual renderer calls at widths 24/48/72/120/144: **32 images and eight invalidCamera throws**. Every returned image had zero unsupported pixels and zero mask bytes. The first five candidates (azimuth 15°, elevation 87°, 200 mm; distances 0.170001/0.1725/0.1775/0.1825/0.1875 m) returned images at every width. The other three became rejected at some larger widths. This corrects the initial parent summary of 40 images.

## Concrete regression witness

Subject (0,0,0), no lights, camera (0.0023027557228276507, 0.16976801953781231, 0.008594001355012789), 200 mm. At width 24, all 384 first entries are clipped and masked; no retained backface exists. Pixel (0,0) has:

- Head entry distance 0.031087885288314295 m, facing +0.9558298543647248.
- Near-plane ray minimum 0.050264379161589184 m.
- Retained neck entry 0.26588763374183777 m, facing +0.5992397119434162.
- First subsequent head exit 0.2847682830149615 m.

Thus the retained neck surface lies inside the original closed-head entry/exit interval. All five widths return images for this witness.

**Recommendation:** preserve this scene as a regression expecting invalidCamera after the correction. Root is implementing first-surface depth rejection with a single traversal from minimum 0; panel-only sub-near rays remain background. No product source was edited by W32; no commit/push.

**Evidence:** wave04-evidence/W32-guard-scan.swift, W32-guard-scan-results.json, W32-guard-scan.stderr, and W32-review-receipt.json. Limits: finite grid; primitive labels reconstruct analytic intervals only; zero-light evidence establishes geometry behavior without a visual-fidelity claim. No Apple/Metal/device acceptance. Later candidate validation belongs to root.
