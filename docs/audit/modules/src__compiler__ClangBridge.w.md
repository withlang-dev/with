# Audit: src/compiler/ClangBridge.w @ 450733e5

Commit: 450733e5 (verified via git rev-parse in workspace /home/shawn/workspace2/with)
Module lines: 4129 (wc -l). Read: lines 1-1973, 1974-~3830, tail 3831-4129 (FULLY READ this pass).
Mode: READ ONLY for compiler sources. No issues filed.

## Targets traced
- T13 ownership/drop: session vs owned-str split, dispose coverage, per-function alloc/free balance.
- T15 migration fidelity: constant names/kinds, struct layouts, translation defaults.
- T22 spec conformance: target predicates, unsupported-type contract, stub TODOs.

## Findings
1. src/compiler/ClangBridge.w:3172-3185 | severity: medium | target: T22 | probe: RAN (stage1 alive; no dedicated runtime case)
   Hardcoded target predicates: with_ci_pointer_width always 8 (3175, null-tu fallback),
   with_ci_sizeof_long always 8 (3181), with_ci_char_is_signed always 1 (3185).
   Correct for LP64 x86_64 Linux / aarch64 Darwin (per inline comments), but
   with_ci_sizeof_long = 8 is wrong for a Windows target (sizeof(long)=4).
   CONFIRMED as latent defect. Caller search redone in REGEX mode over
   src/ tools/ lib/: zero in-repo callers of with_ci_pointer_width /
   with_ci_sizeof_long / with_ci_char_is_signed (only definitions hit) — so no
   live caller impact in-repo today; defect triggers only if a Windows target or
   future caller consumes these predicates.
2. src/compiler/ClangBridge.w:976-977,985-986 vs 930-931 | severity: low | target: T22 | probe: RAN (stage1 alive; code-path verified)
   translate_fn_type silently substitutes "i32" for unsupported arg (976-977) /
   return (985-986) spellings, while the default arm contract (930-931) says
   unsupported must produce a loud __UNSUPPORTED compile error. CONFIRMED
   inconsistency (repo rule: silent fallbacks forbidden, fail loudly).
   translate_fn_type HAS live callers in-module (806, 870), so the silent path is
   reachable on unsupported fn-arg/return spellings.
3. src/compiler/ClangBridge.w:2687-2700 (+ tail 4112-4129) | severity: low | target: T22 | probe: RAN (stage1 alive; code-path verified)
   with_cimport_typedef_anon_record_field_count is a stub: validates decl, then
   always returns -1 with "TODO: implement full anonymous record field enumeration"
   (2700). CONFIRMED unimplemented path with 5 live call sites in src/CImport.w
   (2565, 8490, 15967, 15985, 16009), all guarded `anon_count > 0`, so the stub
   silently takes the skip/non-anon path. Tail adds sibling stubs (4112-4129):
   struct_field_anon_field_count -> 0, anon_field_name/type -> "", 
   typedef_anon_field_name/type -> "", typedef_anon_field_is_bitfield -> 0.
4. src/compiler/ClangBridge.w:258-317 | severity: info | target: T15 | probe: RAN (value cross-check)
   Mixed constant prefixes (CB_CI_CAST_* vs CI_CAST_*, CB_BO_* vs BO_MOD/BO_MOD_ASSIGN,
   CB_UO_* vs UO_BITNOT/UO_LOGNOT/UO_ADDROF). CONFIRMED as style/fidelity wart
   ONLY — no functional defect: numeric values agree with the consumer-side
   constants in src/CImport.w (e.g. BO_MOD=5 vs BO_REM=5 at CImport.w:202;
   BO_MOD_ASSIGN=24 vs BO_REM_ASSIGN=24 at CImport.w:221; UO_BITNOT=2 vs UO_NOT=2
   at CImport.w:265). CImport.w consumers use their own constants; ClangBridge
   returns raw ints that match numerically.
5. T13 (no defect surfaced, coverage now complete): session_make_str ownership split is documented
   (535-544) and dispose (1310-1367) frees caches, tracked strings, cursors/types/child arrays,
   hashes, spellings, tmp_path(+unlink), tu/index/err_msg/decls. Spot-checked alloc/free balance in
   with_ci_cursor_in_file (1926-1993), with_cimport_record_field_offset_by_name (1666-1707),
   collect_field (1049-1064), dispose_macros (2602-2629) — all balanced on read paths. Tail
   (3831-4129: binary/unary op text extraction + CX fallbacks, implicit-cast-kind
   mapping, anon-field stubs) follows the same guarded-return pattern; no new
   ownership defect surfaced. Full leak freedom still NOT established (no runtime
   leak probe).

## Probes run
- P1: git rev-parse in /home/shawn/workspace2/with → 450733e5 confirmed. PASS.
- P2: wc -l src/compiler/ClangBridge.w → 4129. PASS.
- P3: ls out/bootstrap/bin/with-stage1 → EXISTS (114690576 bytes); --version →
  `with v0.15.1.7-g450733e58`. PASS (prior "missing" claim refuted — binary exists).
- P4: seed-compiler smoke probe (`with-stage1 check` on trivial /tmp/cib_probe.w) → `ok`. PASS.
- P5: `with-stage1 check tests/test_cimport.w` → check fails on ENVIRONMENT issues only:
  prelude shadow `int_to_string` (test_cimport.w:118) + missing clang header
  (`<float.h>`: '__float_header_macro.h' file not found, test_cimport.w:182).
  Bridge C-header compile path was exercised (failure is env, not findings F1-F4).

## Negative controls
- N1: caller cross-check redone in REGEX mode (prior literal-mode alternation misuse fixed):
  real results — translate_fn_type: 2 in-module callers (806, 870);
  with_cimport_typedef_anon_record_field_count: 5 CImport.w call sites;
  with_ci_pointer_width/sizeof_long/char_is_signed: zero in-repo callers. True results, not tool misuse.
- N2: runtime probe → PARTIAL (P3/P4 PASS prove stage1 alive; P5 blocked by env headers, not by findings).
- N3: full-module read → MET (tail 3831-4129 read this pass; module fully covered across passes).

## Verdict
Verdict: COMPLETE — full module read (1-4129), regex caller search redone with true results, stage1 probes run; F1 latent-confirmed (no live callers), F2 confirmed (live callers), F3 confirmed (5 call sites + tail sibling stubs), F4 wart-only (values numerically consistent, no functional defect).
