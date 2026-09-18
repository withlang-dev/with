# Audit: src/compiler/Zcu.w @ 450733e5

- Module: `src/compiler/Zcu.w` (541 lines, full read)
- Commit: `450733e5` (`git rev-parse --short HEAD` confirmed)
- Role: Zig-Compilation-Unit state — canonical per-compilation owner of interned
  semantic state, diagnostics, source/import context, and stage snapshots
  (mirrors Zig's `Compilation`/`Zcu` split; `Compilation` drives, `Zcu` holds)
- Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance)
- Probe binary: `out/bootstrap/bin/with-stage1` (`ls -la` + `file`: ELF 64-bit
  LSB executable, x86-64, 114690576 bytes)

## Summary

State-holder module: `Zcu` struct (40+ fields), `Zcu.init`, and ~30 small
accessors/mutators/snapshot setters. No parsing, typing, lowering, or codegen
logic lives here — every method is storage, cloning, lookup, or diagnostic
rendering. All ownership-sensitive branches check out against in-repo callers;
six suspected defects were investigated and refuted below. No surviving
findings.

## Caller map (REGEX-mode searches, `mode:regex`)

- `Zcu.init`: `Compilation.w` (via `zcu` construction per compile entry).
- `sync_from_sema`: `Compilation.w:1537,1849,1877,1884,1901,1914,1933`,
  `Frontend.w:1758` (always after `zcu.diagnostics = move sema.diags` +
  `sema.diags = DiagnosticList.init()` restore, e.g. `Compilation.w:1532-1537`).
- `reset_for_new_invocation`: `Compilation.w:486,1042,1056,1082`.
- `clear_stage_outputs`: `Zcu.w:426` (from `reset_for_new_invocation` only).
- `set_resolve_snapshot`: `Frontend.w:1456,1463,1491,1498,1598,1612`.
- `set_typed_snapshot`: `Compilation.w:1538`, `Frontend.w:1629,1655,1708,1723,1764`.
- `set_codegen_snapshot`: `Compilation.w:1539,1758,1852,1880,1887,1904,1917,1936,1942`.
- `capture_last_link_lib_names`: `Frontend.w:1619` (after `set_resolve_snapshot`).
- `seed/append_decl_source_paths`, `append_c_import_decl_paths`:
  `Frontend.w:1544,1561,1573,1587,1826,2494` (seed before use, appends track merges).
- `add/has_imported_path`: `Frontend.w:1389-1404,1438-1439,1874-1993` (check-then-add).
- `c_import_cache_lookup/store`: `Frontend.w:353,369,418` (key from
  `c_import_cache_key_frontend`, `Frontend.w:480-524`).
- `source_for_file_id_frontend`: `Zcu.w:282,305,343,360`,
  `ComptimeEval.w:4133,4178`.
- `render_all_diagnostics_frontend`: `Compilation.w:901,1879,1886,1903,1916`,
  `Frontend.w:1597,1628,1654,1707,1763`.
- `frontend_sema_completed`: set `Frontend.w:1775` (single site, post-sema);
  gated `Compilation.w:1103` (`check_pool` refuses success verdict when 0).
- `set_frontend_pool`: `Frontend.w:1650` only.
  Readers of `frontend_pool`: `Backend.w:60,206` (debug prints only).
- `tracked_input_root/configure_tracked_input_sema`:
  `Compilation.w:1507,1804,1809`, `Frontend.w:1669,1730`.
- `add_cli_diag_mapping/clear_cli_diag_mappings`: `Compilation.w:644-653`,
  `main.w:717`.
- `add_source_text_mapping`: `Frontend.w:1579,1795,1825,2483`.
- `prelude_prefix_decls/non_use`: zeroed `Frontend.w:1531-1532` each entry,
  set `:1548-1549`, read `:1594,1606,1909,1942`.
- `bundle_corpus/link_bundle_prefixes`: written `Compilation.w:412,415,550`
  (per-invocation `configure`), read `Backend.w:53-54,140-141,202-203,247-248`.

## Probes run (seed `out/bootstrap/bin/with-stage1`, `ls`+`file` verified)

- P1: `check ok.w` (trivial `fn main`) → `ok`, rc=0.
- P2: `check stduse.w` (`use std.collections.HashMap`) → `ok`, rc=0
  (prelude-prefix + import-merge + resolve-snapshot path through Zcu).
- P3: `check bad.w` (undefined call) → `error: undefined variable` with correct
  file/line/caret, rc=1 (diag render via `source_for_file_id_frontend`).
- P4: `check rootbad.w` (`use ./helper.w`, invalid syntax) → parse errors with
  correct spans, rc=1 (no-silent-fallback: failure, not success).
- P5: `check empty.w` (bodyless fn) → `error: expected expression`, rc=1
  (empty-module guard path; `check_pool` decl-count gate intact).
- P6: `run run42.w` (`40 + 2`) → rc=42 (end-to-end through Zcu MIR snapshots).
- Negative controls: P3/P4/P5 each assert rc!=0 plus a diagnostic (not silent
  success); file-relative `use` correctly rejected by the parser (module-path
  imports only — parser authority, not Zcu).

## Findings

None. Verdict: COMPLETE.

## Refuted (reviewed, no finding)

- R1 — `Zcu.init` aliases `pool` into `pool`, `frontend_pool`, and
  `Sema.placeholder(pool, ...)` (`Zcu.w:124,127-128`); `sync_from_sema`
  (`Zcu.w:441,449`) leaves `self.pool` and `self.last_sema.pool` sharing state
  (T13/T15 double-ownership suspect). Refuted: `InternPool` is
  `impl Copy` over `*mut InternPoolState` (`InternPool.w:83-86`) with no-op
  `deinit` (`InternPool.w:115-116`) — a shared handle by design, never freed.
  Same pattern at `Frontend.w:1650` (`set_frontend_pool(self.pool)`).
- R2 — In-memory `c_import` cache never cleared by `reset_import_state` /
  `clear_stage_outputs`, so a stale expansion could leak across invocations
  (T15). Refuted: key (`Frontend.w:480-524`) folds header spec, links, allow,
  no-methods, strict, only, owns, borrows, defines, header content hash,
  compiler fingerprint, and `WITH_CIMPORT_CACHE_EPOCH`. Cross-invocation reuse
  is content-addressed and safe.
- R3 — `reset_for_new_invocation` (`Zcu.w:419-428`) does not reset
  `prelude_prefix_decls/non_use` (T22 stale-prefix suspect). Refuted:
  unconditionally zeroed at `Frontend.w:1531-1532` on every `compile_source`
  entry before any read.
- R4 — `set_resolve_snapshot` (`Zcu.w:453-508`) deep-clones `modules/imports`
  strings but pushes `defs/scopes/bindings/uses` by value — shallow copy of
  owned data (T13). Refuted: all four element types are `impl Copy`
  (`Resolve.w:87,97,105,116`, pure i32 structs); only the `str`-carrying
  `ResolvedModule/ResolvedImport` need clones, and they get them
  (`zcu_owned_text`, `Zcu.w:460,474`).
- R5 — `frontend_sema_completed = 1` set before sema runs, letting a
  parse-stopped pipeline mint success (T22 false-green suspect). Refuted: the
  single set site (`Frontend.w:1775`) is the post-sema return; every earlier
  bail returns with the marker 0, and `check_pool` (`Compilation.w:1103-1108`)
  refuses success when 0 with an explicit `internal error` message.
- R6 — `bundle_corpus` / `link_bundle_prefixes` survive `clear_stage_outputs`
  (T22 cross-build contamination suspect). Refuted: both are per-invocation
  driver configuration overwritten by `Compilation.configure`
  (`Compilation.w:401-415,550`), not per-file stage state; `Backend.w`
  re-reads them per emit.
- Noted, not filed: `render_diag_frontend(&Diagnostic)` borrow form,
  registry-first `source_for_file_id_frontend` (#661), per-file cached render
  (#747), moved-`Vec` sentinel restores (#743), and `sema.diags` restore before
  `sync_from_sema` (#782) are all present and correct in this module.

## T13 / T15 / T22 notes

- T13 (ownership/drop): only structural storage here; all `str` crossings use
  `zcu_owned_text` / `with_str_clone_ref` / `.clone()`; `Copy` types
  (`InternPool`, `ResolvedDef/Scope/Binding/Use`) shared by handle; no drops,
  moves across scopes, or cleanup edges originate in this module.
- T15 (migration fidelity): `zcu_new_vec_str` manual `Vec[str]` literal
  (`ptr:0,len:0,cap:0,elem_size:16`) matches the `str` layout and the sibling
  `frontend_new_vec_str` helper; no C-ABI or layout translation in scope.
- T22 (spec conformance): no normative spec rule governs ZCU internals; the
  observable contracts (success requires completed sema; errors render against
  the owning file with carets; empty modules fail) are probe-confirmed P1–P6.

Verdict: COMPLETE
