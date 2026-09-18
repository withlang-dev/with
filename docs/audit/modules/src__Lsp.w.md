# Audit: src/Lsp.w @ 450733e5

Scope: read-only audit of compiler source `src/Lsp.w` (2078 lines).
Targets: T13 ownership/drop, T15 migration fidelity (where applicable), T22 spec conformance.
Caller: `src/main.w:19` (`use Lsp`), `src/main.w:986-987` (`run_lsp()` on `lsp` CLI), `src/main.w:4475` help text. Only in-repo caller.

## Probes
- `out/bootstrap/bin/with-stage1 check src/Lsp.w` → `ok` (exit 0). EXECUTED.
- `with-stage1 run` of the LSP server: HELD — `run_lsp()` is an interactive stdio JSON-RPC loop; no scripted harness/probe was feasible in this read-only audit.
- Negative controls (all EXECUTED via grep):
  - Alloc/free pairing: single `with_alloc` in `run_lsp` (line ~1889), freed on `exit` path (~1920, followed by `return`, so end-of-function free at ~2077 is not reached) and on loop-break fallthrough (~2077). No double-free path.
  - `move` sites (~474, 489-490, 540, 600, 613) all move freshly built locals into slots/fields, never a cached live buffer.
  - Method dispatch covers `initialize/initialized/shutdown/exit/didOpen/didChange/didSave/hover/definition/formatting/completion/signatureHelp/references/documentSymbol/rename` + `-32601` fallback; framing uses `Content-Length` + `jsonrpc:"2.0"`.

## T13 ownership/drop — no findings
The module documents its ownership hazards inline and codes against them:
- `ensure_doc_parsed`/`ensure_doc_analyzed` (~585-615): decide from a `&` view, then `slot.set(move rebuilt)` with an independently built document; comment explicitly cites the post-#691 double free of get-mutate-set bit-copies.
- `get_parsed` (~616-624): deliberately returns a fresh caller-owned parse instead of sharing cache pools, citing the caller-drop/shutdown-drop double free.
- `publish_diagnostics` (~683-692): reads diagnostics through a view with `comp` kept at function scope; comment cites the lsp-use-std shutdown crash from bit-copying the Vec header.
- `#747` owned snapshots (`with_str_clone_ref` of stored document text before mutating `state`) appear at every state-mutating handler (didSave/hover/definition/formatting/completion/signatureHelp/references/documentSymbol/rename).
- Refutation attempt: suspected double-free between the `exit`-path `with_free` and the tail `with_free` — refuted: the `exit` path returns immediately, so the tail free is unreachable on that path; the break path reaches only the tail free. Suspected stray `msg/tokens` references in `definition` from a sed-window juxtaposition — refuted: `check` passes `ok`, so no such undefined-name defect exists in the real source.

## T15 migration fidelity — no findings
jsmn port (`jsmn_parse`/`jsmn_parse_string`/`jsmn_parse_primitive`, ~104-238) preserves the reference structure: token init to -1, `toksuper`/`parent`/`size` bookkeeping, error codes -1/-2/-3. The close-brace parent-walk differs textually from C-jsmn's for-loop but terminates via the `tok.parent == -1` arm and the final unclosed-token sweep. No behavioral divergence demonstrated; `check` passes and no caller exhibits a parse failure. Refutation: could not construct a failing JSON input from in-repo callers; no defect claimed.

## T22 spec conformance — no findings
- Framing: `Content-Length: <len>\r\n\r\n` on write (~47); header scan + exact-byte body read on input (~33-43).
- Envelopes: `jsonrpc:"2.0"` on results, null-results, notifications, errors (~409-420).
- Lifecycle: `initialize` → capabilities + serverInfo, `initialized` ignored, `shutdown` → null result, `exit` → return 0; unknown methods → `-32601`. Full-sync `contentChanges[0].text` handling; `publishDiagnostics` notification emitted on didOpen/didChange (+save path).
- Refutation attempt: looked for missing `id` echo on errors or wrong method strings — all dispatch arms use the exact LSP method names confirmed by grep; no defect claimed.

## Findings
None.

verdict: COMPLETE
