# Recovery, editing and viewport verification

Starting revision: `968e4bb1b3932c5140b735b404c9538d909bab23`. Integrated revision: `a9a2e8e74d0eb5090ec02948f6e1fe894e7364a1`.
Exact tested Git tree: `1fe0bed45fe7ebd853fdc86a8cb21d1e460ba586`; the GitHub-created tree was checked for equality before moving main.

## Implemented and reviewed

- Confirmed archived-record replacement preserves an unsaved setup at the 64-project limit. Full candidate equality is checked under the existing lock; unrelated latest records survive. If another window has freed space, append without removing an archive.
- One bounded edit-history transaction model replaces separate UI stacks; active edits close on save, view/selection and lifecycle boundaries. Undo/redo controls are disabled during a gesture. Arbitrarily interleaved old/new callback streams remain a documented residual, not a verified native behavior.
- Room half-turns rotate relative to current yaw. Actual point and modifier projections return after two half-turns.
- Overhead and initial 3D views fit authored geometry, including rectangular emitting faces; ordinary 3D edits preserve user orbit. Explicit Fit setup resets framing. Grid work is bounded, adaptively spaced and truthfully labeled.
- Exact numeric accessibility values use one locale-aware formatter. Bounded display labels protect native text layout without changing legacy stored names; explicit new-entry validation and joined international names are supported.
- Cancelling a replacement reference import retains the previous photo, observations and rigs; stale transfers are rejected before UIImage construction.

## Actual verification

Local isolated checkout of the exact staged tree, Debian 13 x86_64, official signature-verified Swift 6.4.3:

```sh
swift test --jobs 2
swift test --configuration release --jobs 2
swiftc -frontend -parse App/*.swift UITests/*.swift NativeTests/*.swift
python3 scripts/native_test_shards.py check
python3 scripts/agent_cycle.py check
```

**180/180 Debug and 180/180 Release tests passed**, zero failures. Native syntax and six-class shard coverage passed. Syntax parsing is not Apple SDK compilation. Raw logs are adjacent. Their host wall-clock timestamps differ from the session UTC clock; they are preserved verbatim and were not used to assert session duration.

GitHub run: https://github.com/mirzotipi-wq/APP1/actions/runs/45351150862. Core job 138297620275 observed success. Native build/unit and three UI shards queued at checkpoint. No native, device, calibration, performance or release gate was promoted.

## Independent challenges and corrections

Separate specialists identified the full-library dead end, unfinished slider-history interleaving, absolute half-turn bug, origin-dependent framing, unbounded Unicode labels and rounded spoken values. Subsequent independent review led to nondestructive recovery when capacity becomes available, a real oversized-encoding failure regression, bounded grid work and capped marker labels. Eight concurrent replacement attempts have one winner in the portable test. Source review is distinct from native UI execution.

Remaining material work includes an editable backup when all 64 records are active, native confirmation and persistence tests, arbitrary interrupted gesture ownership, physical rendering and device performance.

## Raw log SHA-256

- `cycle1-debug.log`: `68a97c7b51e2256a87b0312243d4d57ea7fd1ea5d73072dfff3beaa0dc1914de`
- `cycle1-release.log`: `492df029594717eef7407f65cbe6fb0cb3665fa7b1b2a09ac612fcaf56962ed1`
