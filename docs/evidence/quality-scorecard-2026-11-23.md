# Provisional evidence-only scorecard — 2026-11-23

This is a conservative **20/100 supported-points floor**, not an overall quality, progress percentage or release estimate. Earlier native run verified five native cases (including six simulator Metal parity fixtures and PDFKit) and eight of nine UI scenarios; meter expansion failed. These are historical results, not current physical-device or end-to-end verification. The latest fixes and archive-only deletion are awaiting full current native validation. No additional supported points awarded until a current coherent regression and visual/device review. No protected quality gate changed. No independent review.

| Category | Max | Supported | Transparent allocation |
|---|---:|---:|---|
| Core functionality | 15 | 8 | 3 validated scene/recipes, 2 camera/optics domain, 2 multi-project operations, 1 PDF layout model; remaining 7 require native end-to-end (3), reference workflow (2), AR/manual placement (2) |
| UI/UX | 15 | 0 | Native workflow 5, genuine screenshot/professional review 5, device layouts 3, onboarding/error-state review 2; all pending |
| Lighting accuracy/rendering | 20 | 8 | 5 analytic/area photometry, 3 bounded CPU direct-light and host parity; actual GPU parity 4, calibrated reference comparisons 5, realistic subject/material review 3 pending |
| Performance | 10 | 0 | Physical frame-time 4, memory 2, launch/input latency 2, thermal 2 pending |
| Stability/data integrity | 10 | 4 | 4 portable round-trip, migration, malformed/oversized data and stale-write tests; native persistence 2, interruption/recovery 2, full regression 2 pending |
| Reference analysis/AR | 10 | 0 | Held-out inference/uncertainty 5, physical AR tracking/error 5 pending |
| Accessibility | 5 | 0 | Real-device VoiceOver/Dynamic Type/contrast/controls audit pending |
| Privacy/security | 5 | 0 | Actual privacy/threat-model/deletion audit and disclosures pending |
| Commercial readiness | 5 | 0 | StoreKit and customer validation pending |
| App Store compliance | 5 | 0 | Current Apple requirements, signed distribution, listing and independent review pending |
| Total | 100 | 20 | Evidence floor; all mandatory release gates still apply |

[92/92 Debug and Release, zero failures](https://github.com/mirzotipi-wq/APP1/actions/runs/45274350597/artifacts/14865369722). [Historical native CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45267130194/job/138016896671) and [current source CI](https://github.com/mirzotipi-wq/APP1/actions/runs/45274350597). Actual native simulator Metal max error 1/255; no real-device or calibrated portrait evidence. Do not claim a score of 95 or release readiness until all gates and independent evidence pass. The allocation is an internal review convention, not a replacement for docs/QUALITY.md.
