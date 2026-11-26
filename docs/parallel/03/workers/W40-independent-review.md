# W40 — independent direct-depth review

Worker/runtime/canonical path: `/root/wave04/independent_review`; role: independent review, parent `/root/wave04`. Clean private tree: `/tmp/keyfill03-7f4b/workers/W40-independent-review`, pinned `ace9f2eba068bc31dd04bb2f1e2028af315d6bdb`. Candidate integration HEAD: `03d5823f59b92b68d634303ef443af49be84a1bf` with uncommitted source/test changes; no source edits or builds performed.

## Provenance

Pinned PortraitStudy SHA256: `cdc88507467f31b4e873a8579aa08b954c846dfdb7d2594ed0fc94f51f751db8`. Candidate PortraitStudy: `f406fb496129d82f81dc429cc3bb002fc1b168b5ed771edcff8e449d5e2757cb`. Candidate depth tests: `73a9e53ecac2cb1017e8d2b324ac83c08114a007e9c6b9c02ae212ae1d685b9a`. Inspected pinned source, current candidate diff, camera framing, depth tests, required startup documents, and W32 candidate input receipt; old W32 embedded labels are not candidate provenance.

## Falsification attempt and actual results

Attempt: a clipped panel conceals a later analytic bust intersection and escapes the closed-subject rejection. Python arithmetic passed six exact-decimal bounds: all analytic ears/neck/clothing have minimum local y at least -0.565 (the panel); torso reaches equality. A panel hit requires ray.y < 0, so every later ray point lies below every analytic part. A closer analytic part instead wins the nearest-hit comparison. Thus this candidate counterexample is excluded for these six parts.

Concrete 24×16, 14mm arithmetic ray: camera (1,-0.5549,0), subject zero, pixel (11,15), panel t=0.059640644084907039, camera minimum t=0.064198850043741262. It intersects inside the finite panel and is clipped. This is an arithmetic witness, not an executed renderer result. Head-source snippets are retained separately; no claim of a runtime head/normal proof.

Exact-depth check: first t immediately below/equal/above computed minimum produces reject/accept/accept for closed regions, matching the pinned intersection's inclusive near-root comparison. Source retains shading-normal `>0` and invalid-surface masks; no normal is changed. Mixed overlap surfaces cannot supersede a smaller first distance.

Evidence: `wave04-evidence/W40-panel-proof.json` records inputs, numeric outputs, six bounds, source snippets and receipt hash. No concrete counterexample found within this bounded attempt. No Swift compile, renderer test, normal-transition grid, mesh topology proof, or translated-depth runtime check was executed. Recommend the direct-depth refinement with root's separately serialized regression evidence; these checks alone do not establish full rendering acceptance.
