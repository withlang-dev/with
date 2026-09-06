# Audit — `build/https_fetch.w`

Status: **COMPLETE**
Source revision: `450733e5`
Source examined: full module, 13 lines (single read)

## Scope examined

Tiny build-helper binary: `main` parses `<url> <output>` and delegates to
`std.http https_download`. Applicable targets: T13 (ownership/drop),
T15 (migration fidelity), T22 (spec conformance).

## Probes run

1. `out/bootstrap/bin/with-stage1 check build/https_fetch.w` → `ok`, rc=0.
2. `out/bootstrap/bin/with-stage1 build build/https_fetch.w -o /tmp/https_fetch_probe` → rc=0.
3. `/tmp/https_fetch_probe` (no args) → `usage: https_fetch <url> <output>`, rc=2.
4. `/tmp/https_fetch_probe onlyone` (1 arg) → same usage, rc=2.
5. Fidelity diff (python3, file vs `lib/std/build.w:2203-2215` embedded
   `build_https_fetch_source`) → MATCH, 320 bytes both.
6. Live-download probe NOT run (requires external network; would also
   violate hermetic-probe hygiene). Download path covered by typecheck +
   in-repo caller inspection instead.

## Negative controls

- Sibling helper `build/zlib_gunzip.w:108-112` uses identical
  `fn main -> i32:` shape and `2 = usage / 1 = failure / 0 = ok` codes;
  this module matches that convention.
- `lib/std/build.w:1811` allowlists `https_fetch` as a network tool gated
  behind `target.allow_network()`; `build/selfhost.w:6985` asserts the
  denial diagnostic names `network tool 'https_fetch'` — helper naming is
  load-bearing and unchanged here.
- `docs/feature_plans/libstd-spec.md` lists `http: https_get, https_download`;
  this module consumes (not redefines) that API.

## Findings

No defects. Every candidate failed refutation:

1. (T13, refuted) — Double use of `argv.get(1)` at
   `build/https_fetch.w:9` and `:11`: suspected double-move. Refuted: `get`
   borrows; `++ ""` clones to an owned `str` for the by-value
   `https_download(url: str, ...)` parameter (`lib/std/http.w:243`), so the
   borrow at line 11 remains valid. Probe status: compiled + ran clean
   (probes 1–4); `check`/`build` rc=0 confirms the borrow checker agrees.
2. (T15, refuted) — Drift between `build/https_fetch.w` and the generated
   copy in `lib/std/build.w:2203-2215` (the `build_download_action` path at
   `:2280-2295` compiles the embedded string, not the file). Refuted:
   byte-identical (probe 5, MATCH 320/320). Seed/sdk/pcre2 paths
   (`build/seed.w:107`, `build/sdk.w:525`, `build/pcre2.w:599`) compile the
   file path directly, so both spellings are live and in agreement.
3. (T22, refuted) — Error-information loss: `https_download` returns `-1` on
   non-200 (`lib/std/http.w:243-247`) and the helper collapses all failures
   to rc=1 with a URL-only message. Refuted vs in-repo callers: every caller
   (`build/seed.w:115-116`, `build/sdk.w:533-534`, `build/pcre2.w:607-608`,
   `lib/std/build.w:2296-2303`) branches only on `rc != 0` and emits its own
   diagnostics (including captured stdout/stderr); the contract needs only
   nonzero-on-failure plus the usage rc=2, both verified by probes 3–4.

## Verdict: COMPLETE — no findings; helper is a faithful thin wrapper, ownership-clean and spec-conformant
