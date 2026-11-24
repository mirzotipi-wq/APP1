# Preserve an active main verification run

## Observed problem

Source816e712 workflow45373901992 completed its native unit job with42/42 methods passing, including all three SceneKit tests. Its two active UI shards were cancelled by the next source push. They retained text logs but could not finalize XCTest result bundles; failure screenshots and accessibility attachments were unavailable. The room shard contained an actual completed status failure plus an interrupted second method. Library had one completed pass plus an interrupted second method. Those results remain failed/incomplete, not a passing suite.

This follows multiple recorded superseded native runs during frequent main integration. A policy that always cancels the active suite can repeatedly erase the acceptance evidence needed to investigate failures even while implementation progresses.

## Focused workflow change

Keep the existing workflow/branch concurrency group, and change only its cancellation condition to `github.ref != 'refs/heads/main'`. A main push or manual main run lets the current workflow finish. GitHub's default single pending slot still replaces an older pending revision with the latest queued revision. PR and other branch workflows retain superseded-run cancellation.

GitHub documents a maximum of one active run per group, default replacement of an existing pending run, and optional cancellation of the active run: [official concurrency documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency). No `queue: max`, extra parallel worker, paid runner, new action, raised timeout, skipped test, relaxed assertion or permission change is introduced.

Tradeoff: a newer main revision can wait for the existing bounded workflow to finish. Results must remain associated with their exact source; an older completed pass never certifies the newer queued source. This is preferable for the observed integration pattern because a complete suite can produce actionable evidence while the latest pending source is retained.

## Verification and limits

The existing recursive shard validator passes with all six UI classes assigned exactly once across the same three shards. The changed YAML parses with the available Python YAML parser; scoped whitespace validation passes. These checks do not execute GitHub's concurrency scheduler. The next relevant push must confirm the active main run is retained and the newer run becomes pending; no scheduler success is claimed before that observation.

This is a workflow correction after source3b2a4ce. It does not change or reinterpret the earlier source8 cancellation and failure records. Native and release acceptance remain open.
