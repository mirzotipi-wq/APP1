# Contingent callback trace — proposed only

The current failure is preserved and no source cause is established. A fresh-host rerun of the unchanged failed job is a proportionate next observation after the failed warm-up and actual keyboard-queue timeout. Implement this diagnostic only if that rerun repeats the text-entry failure or otherwise leaves the delivery boundary unresolved. Do not call the rerun a repair or erase attempt1.

## Minimal scope

Add a private trace helper in `App/StudioTextField.swift`, entirely inside `#if DEBUG`. Enable it only when a dedicated `KEYFILL_UI_TEXT_INPUT_TRACE=1` launch environment flag is present. Set that flag in the existing required accessibility workflow's app launch configuration; leave all interaction calls, assertions, values, deadlines, test names and captures intact. Do not add an accessibility element, alter `accessibilityValue`, touch the keyboard, force focus, or change text to transport the trace.

Give each native control a monotonically assigned process-local diagnostic ID. Emit ordered JSON lines prefixed `KEYFILL_INPUT_TRACE_V1`, capped at256 records per control and512 per process, plus one explicit truncation marker. Include timestamp/sequence, event name, lifecycle ID, field identifier, `isEnabled`, `isFirstResponder`, marked-text presence, relevant guard flags and UTF-16 lengths/equality flags. Never emit raw text, replacement characters, project names, logs supplied by users or stable device identifiers. Cap identifiers to known app identifiers or a small byte limit.

Record only these useful boundaries:

- Initial or materially changed configuration; external-value reset; identity change and invalidation.
- `shouldChangeCharactersIn` entry and acceptance/rejection, range location/length and replacement UTF-16 length.
- `editingChanged`/submit/end-edit entry, binding-write attempt and accepted-value equality/length, plus any subsequent native-text restoration.
- Native focus begin/end and the requested/actual focus state around the existing asynchronous synchronization.

Record existing decisions without recomputing or changing them. Avoid per-character content, unbounded configuration noise, new UIKit queries, thread waits or timers. Debug logging itself can affect scheduling; an instrumented pass is source-specific evidence, not proof of the historical cause.

## Evidence route

Write complete bounded lines to app stdout. The **existing full finalized xcresult upload** already retains app stdout and XCTest session diagnostics: worker095 recovered both from the actual current failure. Keep that full artifact, its provider digest, source SHA and selected raw diagnostic files. The compact attachment archive alone does not retain these process logs. Extract the trace from the original app diagnostic log, retain its entire bounded sequence and original file hash, and correlate against the same runner synthesis and assertion timestamps. No additional failure-time AX request is required for transport.

## Falsifiable interpretation

Zero delegate/editingChanged callbacks after synthesis supports investigating the delivery boundary; it does not by itself identify a host or product cause. Callbacks followed by a rejected binding or external reset identify the exact bridge/caller branch for a targeted reproduction. A lifecycle change or focus loss before delivery identifies another concrete branch. Preserve absent/truncated trace as unavailable evidence.

If implemented, a narrow native verification should confirm tracing leaves accepted/rejected edit, selection and focus behavior unchanged, and that a confidential canary text never appears in output while the cap/truncation marker works. Linux source parsing cannot establish those UIKit invariants. No implementation or test was performed by worker096.
