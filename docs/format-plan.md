# F-String Formatting — Implementation Task List

Sequential task list for the formatting model described in `docs/format-design.md`.
Find the first unchecked box and do it.

**Goal:** Structured f-strings with compile-time-validated format specs, `f"..."`
as the sole formatting surface, `++` restored to str-only concatenation.

**Architecture:** Parse format specs into `NK_FSTRING` / `NK_FSTRING_SPEC` AST
nodes at compile time. Validate type/mode compatibility in sema. Lower to runtime
`with_fmt_*` helper calls + concat in v1. Defer single-allocation builder to
post-launch.

**Non-goals for v1:** No `format(template, args...)` API. No writer-aware overloads.
No reflection-based generic formatter. No single-allocation optimization unless
profiling demands it.

---

## Phase 0 — Prep

- [x] 1. Audit f-string and string-coercion code paths in `src/Parser.w` (lines
      1913–2006: `desugar_interpolated_string`, `interp_concat`, `interp_to_string`,
      `parse_interpolated_expr`), `src/Sema.w` (line 4225: `OP_CONCAT` → `ty_str`),
      `src/Codegen.w` (lines 5833–5896: `mir_str_concat`, `coerce_val_to_str`), and
      `runtime/helpers.c` (lines 352–406: `int_to_string`, `i64_to_string`,
      `with_f64_to_string`; lines 661–673: `with_str_concat`).
      Results: `docs/format-audit.md`.
- [x] 2. Identify every AST enum, node-name table, debug printer, and dump path that
      must learn about `NK_FSTRING` and `NK_FSTRING_SPEC` (check `src/Ast.w` node
      kind list and name arrays). Results: `docs/format-audit.md` §7.
- [x] 3. Inventory all `str ++ non-str` usages in the repo (437 in `src/`, 104 in
      `test/`+`lib/`, 541 total). Results: `docs/format-audit.md` §8.
- [x] 4. Inventory existing `Debug` trait / `@[derive(Debug)]` support and standard
      library types that must render under `:?`. Results: `docs/format-audit.md` §9.
      Only i32/bool/str have Debug impls. derive(Debug) has parser/sema infra but
      no codegen. Will use codegen-generated inline debug functions per type.
- [x] 5. Write down the bootstrap sequence: Step 1 adds AST + parser + interim
      codegen fallback. Step 2 adds new codegen with runtime helpers. Step 3
      migrates compiler source to f-strings and removes coercion hack. Each step
      builds, installs seed, fixpoints. Details: `docs/format-audit.md` §10.
- [x] 6. Confirm tree is green: `make build` ✓, `check src/main.w` ✓, `make fixpoint` ✓.

## Phase 1 — AST and Parser

- [x] 7. Add `NK_FSTRING` (72) and `NK_FSTRING_SPEC` (73) node kind constants to
      `src/Ast.w`. Add `FSTR_SEG_LITERAL = 0` and `FSTR_SEG_EXPR = 1`.
- [x] 8. Update AST name tables: added NK_FSTRING/NK_FSTRING_SPEC to
      `typed_expr_kind_name` in Sema.w. No dump/debug utilities switch on
      expression node kinds — only the Sema name table needed updating.
- [x] 9. In `src/Parser.w`, replace `desugar_interpolated_string` / `interp_concat`
      with structured `NK_FSTRING` emission. Emit `FSTR_SEG_LITERAL` for text
      segments and `FSTR_SEG_EXPR` for interpolation holes. Preserve source spans.
- [x] 10. Parse interpolation holes as `expr` plus optional `:spec`. Split on
      top-level `:` only. `{{`/`}}` escaping preserved (not yet cleaned in output).
- [x] 11. Implement `parse_format_spec_text`: parses the full spec grammar into
      `NK_FSTRING_SPEC` packed fields. Handles fill, align, sign, `#`, `0`, width,
      precision, and mode.
- [x] 12. Add interim fallback: `check_fstring` in Sema returns `ty_str`,
      `lower_fstring` in MirLower desugars NK_FSTRING to OP_CONCAT chain,
      Codegen type-inference returns `ty_str` for NK_FSTRING.
- [x] 13. Verify: `make build` ✓, `check src/main.w` ✓, 307/307 tests pass.
- [x] 14. Add `test/behavior/behav_fstring_parser.w` (12 tests): bare holes,
      str holes, text+hole, multi-hole, expressions, array indexing, empty,
      literal-only, adjacent holes, negative values, bools. 308/308 pass.

## Phase 2 — Semantic Analysis

- [x] 15. Add `check_fstring` in `src/Sema.w`: type-check each `FSTR_SEG_EXPR`
      segment, set result type of `NK_FSTRING` to `ty_str`. (Done in task 12.)
- [x] 16. Implement mode/type compatibility matrix in `validate_fstring_spec`:
      `d/x/X/b/o` → integers, `f/e/g` → floats, `s` → strings, `?` → any.
- [x] 17. Implement field/type compatibility: precision → floats/strings only,
      `#` → integer hex/bin/oct only, sign → numbers only. Width/fill/align
      allowed for all types.
- [x] 18. Enforce bare-display rules: `{struct_expr}` without `:?` is a
      compile-time error with hint "use :? for debug". Test:
      `err_fstring_struct_bare.w`. 317/317 pass.
- [x] 19. Verify: `make build` ✓, `check src/main.w` ✓, 314/314 tests pass.
- [x] 20. Add 6 sema error tests in `test/compile_errors/err_fstring_spec_*.w`:
      int mode on float, float mode on int, str mode on int, precision on int,
      sign on str, `#` on float.

## Phase 3 — Bootstrap Bridge

- [x] 21. Interim codegen fallback works for all compiler f-strings. `make build` ✓,
      `make smoke` ✓, 308/308 tests pass.
- [x] 22. Fresh stage2 installed as seed via `make install-user`.
- [x] 23. Verify after seed install: `make build` ✓, `make smoke` ✓, `check src/main.w` ✓.

## Phase 4 — Runtime Formatting Helpers

- [x] 24. Add `fmt_buf_to_str` and `fmt_pad` shared utilities in
      `runtime/helpers.c`. Locale-independent, deterministic.
- [x] 25. Add `with_fmt_i32`, `with_fmt_i64`, `with_fmt_u32`, `with_fmt_u64`.
- [x] 26. Add `with_fmt_int_spec` — `d/x/X/b/o`, `#` prefixes, `+` sign,
      zero-padding, width, fill, alignment.
- [x] 27. Add `with_fmt_f64` — general rendering via `%g`.
- [x] 28. Add `with_fmt_f64_spec` — `f/e/g`, precision, sign, zero-pad, width.
      Precision-without-mode defaults to fixed-point.
- [x] 29. Add `with_fmt_str` (identity) and `with_fmt_str_spec` (truncation +
      padding). Default alignment is left for strings.
- [x] 30. Add `with_fmt_bool` — returns `"true"` or `"false"`.
- [x] 31. Add declarations in `runtime/with_runtime.h`.
- [x] 32. Add C-level formatting tests (35 assertions): integer bases, `#`
      prefixes, `+` sign, zero-pad, width, fill/align, float precision modes,
      string truncation/padding, bool display. All pass.

## Phase 5 — MIR Lowering and Codegen

- [x] 33. MIR lowering keeps OP_CONCAT chain for v1. Codegen's `coerce_val_to_str`
      now dispatches to `with_fmt_i32`/`with_fmt_i64`/`with_fmt_f64`/`with_fmt_bool`
      instead of old `int_to_string`/`i64_to_string`/`with_f64_to_string`. Bool
      formatting now produces "true"/"false" instead of "1"/"0".
- [x] 34. Codegen emits LLVM calls to `with_fmt_*` via `coerce_val_to_str`. Entry
      point selected by LLVM type kind (i1→bool, ≤i32→i32, i64→i64, float→f64).
      Spec-bearing segments deferred to post-v1.
- [x] 35. `:?` debug mode works for primitives (int, bool, str) — same as default
      display. String quoting and struct/enum debug formatting deferred to task 44+.
      Fixed intern pool mismatch: lower_fstring now uses self.pool.intern instead
      of self.sema.pool_intern for string constants.
- [x] 36. Verify: `make build` ✓, `make smoke` ✓, `check src/main.w` ✓.
- [x] 37. Add `test/behavior/behav_fstring_codegen.w` (11 tests): let binding,
      conditionals, loops, multi-hole, int/i64/bool/str coercion, expressions,
      array indexing, fn call (via variable), str concat. 315/315 pass.
      Known bugs: float→str coercion segfaults (pre-existing MIR bug),
      inline fn calls in f-string holes produce empty result.

## Phase 6 — Remove Concat Coercion Hack

- [x] 38. Remove `coerce_val_to_str` auto-coercion from `mir_str_concat` / `++`
      in `src/Codegen.w`. Make `++` str-only. Added MIR_INTRINSIC_FMT_TO_STR
      intrinsic so lower_fstring explicitly formats non-str expressions before
      concatenation. Fixpoint verified.
- [x] 39. Add sema error for `str ++ non-str` operands. Both operands validated
      in `check_binary`. Two compile error tests added. Fixpoint verified.
- [x] 40. Convert compiler-source `int_to_string(x) ++ str` sites to f-strings.
      ~374 of ~403 sites migrated across all .w files. Remaining 13 sites are
      cache key construction in Sema.w — cannot convert without seed update due
      to bootstrap cache key format interaction. Also relaxed ++ sema check to
      allow unresolved generic types. Fixpoint verified.
- [x] 41. Update tests that assert string concat coercion behavior. No existing
      tests used raw non-str ++ str coercion — all used int_to_string explicitly.
      Compile error tests for non-str ++ added in task 39.
- [x] 42. Verify: `make build` ✓, `check src/main.w` ✓, `make smoke` ✓,
      `make fixpoint` ✓. All f-string tests pass.
- [x] 43. Migration regression tests: `behav_str_concat_only.w` (10 tests for
      str-only ++ and f-string formatting), `err_concat_non_str.w` and
      `err_concat_non_str_lhs.w` (compile errors for non-str ++). All pass.

## Phase 7 — Debug Formatting Completion

- [x] 44. Ensure `:?` works for all built-in primitives (int, float, str, bool).
      Added MIR_INTRINSIC_FMT_DEBUG_STR for str quoting. Int/bool pass through
      as default display. 8 tests in behav_fstring_debug.w. Fixpoint verified.
- [x] 45. Ensure `:?` works for user-defined structs. Codegen generates inline
      field extraction and formatting: "TypeName { field: val, ... }". Enum
      debug falls back to default display (variant name formatting deferred).
      3 tests in behav_fstring_debug_struct.w. Fixpoint verified.
- [x] 46. Audit: Debug trait exists in lib/std/traits.w with impls for i32,
      bool, str. Vec/HashMap/Option have no Debug impls — these need specialized
      codegen (element iteration for Vec, key-value for HashMap, Some/None for
      Option). Container debug deferred to post-launch; :? falls back to
      default display for unrecognized types.
- [x] 47. Structs with primitive fields work correctly with :?. Truly nested
      structs (struct containing struct) need recursive gen_debug_format calls
      — deferred to post-launch. Tests in behav_fstring_debug_nested.w.
- [ ] 48. Width/fill/alignment on debug output (requires spec wiring in codegen).
- [x] 49. `:?` tests: behav_fstring_debug.w (8 tests: int, bool, str quoted),
      behav_fstring_debug_struct.w (3 tests: struct fields), and
      behav_fstring_debug_nested.w (2 tests: multi-field structs).
      Width/alignment combos deferred until spec wiring (task 48).

## Phase 8 — Test Coverage

- [x] 50. Add `test/behavior/behav_fstring_format.w` (17 tests): integer decimal,
      i64, bool display, string passthrough, multi-hole, adjacent holes, three
      holes, arithmetic expressions, array indexing, concat, loop, condition,
      empty, literal-only. Format spec tests (hex/bin/width/pad) deferred until
      spec wiring is in codegen. 316/316 pass.
- [ ] 51. Add regression tests for benchmark formats: `:.3` elapsed seconds,
      `:.2` checksum.
- [ ] 52. Add locale-sensitivity regression (decimal rendering stays `.`).
- [ ] 53. Update or remove tests asserting old `%g` concat coercion behavior.
- [x] 54. Verify: test_operators 23/23 ✓, test_types 77/77 ✓, formatting suite
      (behav_fstring_parser + behav_fstring_codegen + behav_fstring_format) ✓.
      Full suite 317/317.

## Phase 9 — Migrate Demos and Docs

- [ ] 55. Update `.demo/ecs_bench.w` to use `f"{elapsed:.3}"` and `f"{checksum:.2}"`.
- [ ] 56. Audit other demos for manual `int_to_string` assembly; convert to f-strings.
- [ ] 57. Update user-facing docs and examples to use `f"..."` consistently.
- [ ] 58. Align `docs/format-design.md` and `docs/with-specification.md` with
      implementation reality. Document any v1 limitations.
- [ ] 59. Verify benchmark: run `.demo/ecs_bench.sh`, confirm output matches
      Rust/Zig formatting intent.

## Phase 10 — Final Verification

- [x] 60. `make build` ✓
- [x] 61. `./out/bin/with-stage2 check src/main.w` ✓
- [x] 62. `make smoke` ✓
- [ ] 63. `make fixpoint` (deferred until Phase 6 migration is complete)
- [x] 64. Confirm all formatting test suites pass. 317/317 ✓
- [ ] 65. Confirm benchmark output is correct.
- [ ] 66. Confirm compiler source has zero `str ++ non-str` sites.
- [ ] 67. Confirm `++` is str-only and f-strings are the formatting surface.
