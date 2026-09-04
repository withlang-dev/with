# Primary verification — `lib/std/zlib/defs.w`

Status: **INCOMPLETE** (one minor execution-verified defect, F1)
Primary verifier: primary (structural read + probe execution)
Source revision: `450733e5`
Source examined: `:1–200` fully (ctype helpers, libc/math externs,
C-type aliases, overflow-builtin shims); `:272–480` via targeted
reads (zlib scalar types, `z_stream_s`, `internal_state`,
`gz_header_s`, all `Z_*`/limit/version constants); `:1211`
(`z_errmsg` table); remaining struct/table interiors by shape only.

## Scope examined

Shared definitions: C type aliases (`c_int`…`c_ulonglong`), zlib types
(`z_stream_s` `:307`, `internal_state` `:304`, `gz_header_s`,
`ct_data_s`, braid/table types), return codes / levels / strategies /
flush modes / `MAX_WBITS` / `MAX_MEM_LEVEL`, `ZLIB_VERSION*` identity,
`UINT_MAX`/`INT_MAX`/`ULONG_MAX` limits, `z_errmsg` (`:1211`),
`zlib_version` (`:487`), ctype helpers (`:3–31`). The file declares
**no imports**. Consumers: every `lib/std/zlib/*.w` engine module plus
`build/zlib_gunzip.w`. (Header comment `:1` still says "migrated
PCRE2" though the file serves zlib — doc nit, not filed.)

## Behavioral matrix (EXECUTED vs HELD, oracles independent)

EXECUTED — `docs/audit/probes/zlib_defs/probe.w` via
`out/bootstrap/bin/with-stage1 run` (EXIT 0): all return codes
(−6…2), levels/strategies/flush/window constants, version identity
(`ZLIB_VERSION=="1.3.2"`, `VERNUM==0x1320`), limits incl.
`ULONG_MAX==0xffffffffffffffff`, 20 ctype assertions (ASCII facts).
All 5 `ok` lines in `output.txt`. PASS. Types are additionally
exercised transitively by every other zlib probe (compress/uncompress
drive `z_stream_s`; checksums drive `c_ulong`).
HELD — precomputed-table interiors beyond `z_errmsg`/`crc_table[1]`
(covered behaviorally through checksum/deflate probes, not
cell-by-cell).

## Findings

- F1 (execution-verified, NOT filed): `defs.w:487`
  `pub let zlib_version: *const i8 = zlibVersion()` calls
  `zutil.w`'s `zlibVersion` but the file declares no `use` imports, so
  a lone `use std.zlib.defs` fails check. Observed:
  `error: undefined variable ... defs.w:487:35 ... ^^^^^^^^^^^`
  (saved in `docs/audit/probes/zlib_defs/standalone_import_error.txt`,
  EXIT 1; minimal repro `standalone_only.w`). Expected: a module is
  self-sufficient and checks standalone. It compiles today only
  because every real importer also transitively imports `zutil`
  (e.g. via `adler32.w:3`). Refutation of severity: no behavioral
  impact through any existing import path — all engine, facade, and
  build callers import `zutil` transitively, and every probe here
  passes. Fix direction (not applied — read-only audit): add
  `use std.zlib.zutil` to `defs.w` or move `zlib_version` into
  `zutil.w`.

Verdict: INCOMPLETE (F1 open; all behavior green)
