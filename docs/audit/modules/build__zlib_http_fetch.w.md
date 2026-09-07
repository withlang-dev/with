# Audit: build/zlib_http_fetch.w @ 450733e5 — COMPLETE

Module: 90-line hand-written build helper (plain-HTTP download client).
Commit: 450733e5. Landed intent: 6e73f5f7 "Make zlib reference pipeline self-contained".
Role: compiled on demand by `run_zlib_reference_action` (build/zlib.w:252-262) and
driven once with `http://zlib.net/fossils/zlib-1.3.2.tar.gz` (build.w:2975);
downloaded archive is sha256-pinned (build/zlib.w:263-265) before use.
Scope: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.
No test file covers this module (no hits for `zlib_http_fetch|http_get_body|http_host|http_path`
under tests/ or build/ besides the caller and the usage string) — claimed coverage: none, verified.

## Verdict: COMPLETE — no numbered defects. All probed behaviors match in-repo caller needs and landed intent.

## Targets traced
- T13 (ownership/drop): no owned-heap types in module (str/i32/i64/Result only).
  Socket fd closed on every post-connect path: send-fail closes (L54), normal path
  closes (L62) before all later early-returns (L63-69). `let _close*` bindings
  (L54, L62) discard correctly. No leak/double-close. Build-graph ownership intact:
  build.w:2972 declares `build/zlib_http_fetch.w` as an input of `zlib-reference`.
- T15 (migration fidelity): N/A — hand-written helper, not migrated C. No migration
  source, no fidelity claim to check.
- T22 (spec conformance): `check` clean, `build` clean, runtime CLI contract holds
  (usage/exit 2; errors print + exit 1; Ok path exits 0). All std APIs used resolve:
  `tcp_connect/send/recv/socket_close` (lib/std/net.w:25-38),
  `write_file` (lib/std/fs.w:57), `args` (lib/std/process.w:33).

## Probes run (seed out/bootstrap/bin/with-stage1)
1. `check build/zlib_http_fetch.w` → `ok`, exit 0. PASS
2. `build build/zlib_http_fetch.w -o /tmp/zlib_http_fetch_probe` → exit 0. PASS
3. No-args → `usage: zlib_http_fetch <url> <output>`, exit 2. PASS
4. `https://example.com/x` → `only plain http:// URLs are supported`, exit 1. PASS
5. `http://127.0.0.1:1/x` → `could not connect to 127.0.0.1:1`, exit 1. PASS
6. /tmp logic harness (verbatim copies of `zlib_index_of/http_host/http_path` + 12
   assertions incl. the exact caller URL split `zlib.net` + `/fossils/zlib-1.3.2.tar.gz`)
   via `with-stage1 run` → `HARNESS_ALL_PASS`, exit 0. PASS
7. Positive end-to-end body fetch: ATTEMPTED, FAILED environmentally (not a module
   defect) — helper hardcodes port 80 (`tcp_connect(host, 80)`, L49) and the sandbox
   cannot listen on port 80 (bind traceback in /tmp/zlib_probe_srv80.log); a probe
   server on 8932 was reachable by curl but the helper correctly treats
   `127.0.0.1:8932` as part of the hostname per its plain-host design.

## Refuted non-findings (investigated, rejected as defects)
- R1 explicit `:port` in URL unsupported (host keeps `:port` suffix, always dials 80):
  refuted — sole in-repo URL (build.w:2975) has no port; error string declares
  "only plain http:// URLs" scope. Limitation by design, matches landed intent.
- R2 no redirect/HTTPS/chunked-encoding support; only `HTTP/1.x 200` accepted:
  refuted — same scope argument; sha256 pin (build/zlib.w:263) guards integrity;
  failure mode is loud (nonzero exit → `zlib_fail`), never silent corruption.
- R3 single `send()` without partial-write loop (L53): at most a loud spurious
  retryable failure on an already-loud error path; no corruption vector. Observation only.

## Negative controls
- Bad-scheme and unroutable-host inputs produce distinct correct errors/exits.
- `tests/` + `build/` search confirms zero dedicated tests — no false coverage claim.

Verdict: COMPLETE
