# Evidence ledger format

Append entries to evidence.json, preserving prior results. Required fields: gate (exact ID from state), result (pass/fail/unverified), revision (exact tested 40-character commit SHA for pass), date (a real calendar date in YYYY-MM-DD format), method (actual command or procedure), environment (hardware, OS, SDK, build configuration), artifact (durable path or URL), reviewer (actual identity or explicitly self-review), and notes (numeric results, limitations, fixture, sample size, rationale). Record failures and missing capabilities.

## Current and historical observations

The optional `scope` field is either `current` or `historical`. Existing entries without this field retain the original `current` behavior. The **last current observation** for each gate controls its status. A later current `fail` or `unverified` observation revokes an earlier pass. Historical observations are validated and retained but never change the current gate, including when no current observation exists.

Use `scope: "historical"` when recording a delayed result for an older revision that does not establish the gate for the current implementation. For example, after a source change records `native_build: unverified` at revision B, a delayed successful run at revision A must be recorded as historical; appending it must not silently turn B's native gate green. This addresses the observed risk of delayed CI results being appended after current invalidations without discarding either result.

An older tested revision can still support a current gate when relevant code and assumptions are demonstrably unchanged. Record that comparison and rationale in `notes`, and use current scope deliberately. The checker does not require all gates to use one revision and does not infer applicability from dates or commit order. Its `status` output shows each selected observation's revision so the reviewer can assess that provenance.

## Structural checks and limits

State and evidence roots must be objects with integer schema version 1; booleans are not schema versions. Milestones need nonblank IDs and names, valid statuses, unique string gate/dependency lists, and satisfied dependency ordering. Evidence entries must be objects in a list with the required nonblank text fields, a valid result, an allowed scope and a valid date. Passing observations require a complete tested SHA.

The checker validates structure, not authenticity, artifact existence or freshness. Agents must examine evidence and invalidate affected gates after changes. Release review must audit the full ledger against the integrated revision. No synthetic user interviews or fake CI. The regression suite is `python3 -m unittest discover -s scripts/tests -p 'test_agent_cycle.py'`; its synthetic fixtures are validator tests, not product evidence.
