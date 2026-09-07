# Audit: src/BuildGraphTools.w @ 450733e5

Commit: 450733e5 (`build: the regex runtime shim compiles pcre2 from source under any compiler (--bundle-corpus std/re on the ir lanes)`). Workspace: /home/shawn/workspace2/with. Mode: READ-ONLY (no compiler sources modified).
Module: 86 lines. Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

Verdict: COMPLETE

Findings: none.

Target traces:
- T13 ownership/drop: grep `drop|destructor|free|move|borrow|own*|clone|copy|leak` -> 0 hits
- T15 migration fidelity: grep `TODO|FIXME|XXX|HACK|unimplemented|todo!|panic!|unreachable!|stub|SKIP` -> 0 hits
- T22 spec conformance: grep `spec|conform|invariant|contract|require|ensure|assert` -> 0 hits

Probes:
- P1 seed check `with-stage1 check src/BuildGraphTools.w` -> exit 0 — EXECUTED. Output excerpt: `ok`
- N1 negative control `with-stage1 check src/DoesNotExist.w` -> exit 1 — EXECUTED (expects nonzero; confirms check gate is live, not vacuously passing). Output excerpt: `error: cannot open '/home/shawn/workspace2/with/src/DoesNotExist.w'
error: check failed during compilation`
- P2 behavioral run probe of exported BuildGraphTools functions -> HELD (reason: audit limited to `check` gate; per-function run harness would require resolving module import/call syntax, out of scope for read-only source audit; no behavioral claim made beyond check gate).

Notes: report written to docs/audit/modules/src__BuildGraphTools.w.md. No upstream issues filed. Compiler sources unmodified (verified via `git status --porcelain` on module path).
