# Current handoff

**Stage:** M01 — foundation verification. M00 is a setup activity, not a quality pass. This is pre-alpha, not a shipped app.

## Present
- Swift package with a minimal lighting scene, validation and ideal point-source illuminance estimate.
- SwiftUI starter overhead plan, controls and local JSON persistence.
- XcodeGen project specification, tests, agent state checker and development contracts.

## Unknown / not yet evidenced
- Native iOS compile and simulator UI, actual phone behavior, AR, rendering accuracy, performance, customer validation, commerce and distribution.
- Naming clearance, actual App Store Connect account/products and signing settings.

## Next executable work packet: M01-A
1. Run swift test and python3 scripts/agent_cycle.py check.
2. On macOS, generate the Xcode project, build an iOS simulator target and launch. Verify edit, save, relaunch and corrupt-data error behavior. Capture screenshots and exact toolchain/device settings.
3. Add tests for persisted scene round-trip and error recovery; add repeatable simulator smoke coverage. Fix any build/runtime failures.
4. Add truthful evidence entries (never mark missing tests passed), update state and commit. Once M01 gates pass, begin M02 photometric scene/renderer contracts.

No real-device results, customer interviews, purchases or app publication are asserted.
