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
- [ ] 18. Enforce bare-display rules: `{struct_expr}` without `:?` is a
      compile-time error with hint. (Deferred — struct formatting not yet impl.)
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

- [ ] 24. Add `fmt_buf_to_str` and `fmt_pad` shared utilities in
      `runtime/helpers.c` (heap-copy formatted buffers, apply width/fill/alignment).
      Locale-independent, deterministic.
- [ ] 25. Add default integer helpers: `with_fmt_i32(val)`, `with_fmt_i64(val)`,
      `with_fmt_u32(val)`, `with_fmt_u64(val)` — decimal rendering via `snprintf`.
- [ ] 26. Add integer spec helper: `with_fmt_int_spec(val, is_unsigned, flags,
      width, precision, mode)` — supports `d/x/X/b/o`, `#` prefixes, `+` sign,
      zero-padding after sign/prefix.
- [ ] 27. Add default float helper: `with_fmt_f64(val)` — general rendering via
      `snprintf %g`.
- [ ] 28. Add float spec helper: `with_fmt_f64_spec(val, flags, width, precision,
      mode)` — supports `f/e/g`, precision, sign, width. Handle `NaN`/`inf`/`-inf`.
- [ ] 29. Add string helpers: `with_fmt_str(val)` (identity/copy),
      `with_fmt_str_spec(val, flags, width, precision)` (truncation + padding).
- [ ] 30. Add bool helper: `with_fmt_bool(val)` — returns `"true"` or `"false"`.
- [ ] 31. Add headers/extern declarations in `runtime/with_runtime.h` for the
      `with_fmt_*` family.
- [ ] 32. Add focused runtime tests: integer bases, `#` prefixes, `+` sign,
      zero-pad, width, fill, alignment, float precision modes, string truncation,
      bool display, `NaN`/`inf`.

## Phase 5 — MIR Lowering and Codegen

- [ ] 33. Teach MIR lowering (`src/MirLower.w`) to lower `NK_FSTRING`: literal
      segments become string constants, bare expression segments become
      `with_fmt_{type}(val)` calls, spec-bearing segments become
      `with_fmt_{type}_spec(val, ...)` calls. Concat all segments with `OP_CONCAT`.
- [ ] 34. In codegen (`src/Codegen.w`), emit LLVM calls to the `with_fmt_*`
      runtime functions. Select entry point by static type. Encode spec fields
      into the runtime call ABI.
- [ ] 35. Handle `:?` debug formatting: generate per-type inline debug functions
      in codegen (Option A from design doc). Structs emit
      `"TypeName { field: val, ... }"`, enums emit `".Variant"`, etc.
- [ ] 36. Verify: `make build && make smoke && ./out/bin/with-stage2 check src/main.w`.
- [ ] 37. Add codegen regression tests: f-strings in expressions, loops,
      conditionals, closures, method calls, aggregate literals, and multi-hole
      f-strings.

## Phase 6 — Remove Concat Coercion Hack

- [ ] 38. Remove `coerce_val_to_str` auto-coercion from `mir_str_concat` / `++`
      in `src/Codegen.w`. Make `++` str-only.
- [ ] 39. Add sema/codegen error for `str ++ non-str` operands.
- [ ] 40. Convert all ~367 compiler-source `int_to_string(x) ++ str` sites to
      f-strings: `f"{x}"`. Includes `src/compiler/Backend.w`, diagnostic messages
      in `src/Sema.w`, `src/Codegen.w`, etc.
- [ ] 41. Update tests that assert string concat coercion behavior.
- [ ] 42. Verify: `make build && ./out/bin/with-stage2 check src/main.w && make smoke`.
- [ ] 43. Add migration regression tests: f-strings cover intended use cases,
      `++` rejects non-string operands.

## Phase 7 — Debug Formatting Completion

- [ ] 44. Ensure `:?` works for all built-in primitives (int, float, str, bool).
- [ ] 45. Ensure `:?` works for user-defined structs and enums.
- [ ] 46. Audit standard library containers (Vec, HashMap, Option) and add
      missing `Debug` implementations.
- [ ] 47. Ensure nested debug formatting composes (struct containing struct).
- [ ] 48. Ensure width/fill/alignment wrap the final debug output.
- [ ] 49. Add `:?` tests for primitives, structs, enums, nested aggregates, and
      width/alignment combinations.

## Phase 8 — Test Coverage

- [ ] 50. Add `test/behavior/behav_fstring_format.w` comprehensive test file
      covering: integer `d/x/X/b/o` modes, float `f/e/g` modes, string width and
      truncation, bool display, `#` prefixes, `+` sign, zero-pad, fill/align.
- [ ] 51. Add regression tests for benchmark formats: `:.3` elapsed seconds,
      `:.2` checksum.
- [ ] 52. Add locale-sensitivity regression (decimal rendering stays `.`).
- [ ] 53. Update or remove tests asserting old `%g` concat coercion behavior.
- [ ] 54. Verify: `./out/bin/with-stage2 run tests/test_operators.w &&
      ./out/bin/with-stage2 run tests/test_types.w` and the new formatting suite.

## Phase 9 — Migrate Demos and Docs

- [ ] 55. Update `.demo/ecs_bench.w` to use `f"{elapsed:.3}"` and `f"{checksum:.2}"`.
- [ ] 56. Audit other demos for manual `int_to_string` assembly; convert to f-strings.
- [ ] 57. Update user-facing docs and examples to use `f"..."` consistently.
- [ ] 58. Align `docs/format-design.md` and `docs/with-specification.md` with
      implementation reality. Document any v1 limitations.
- [ ] 59. Verify benchmark: run `.demo/ecs_bench.sh`, confirm output matches
      Rust/Zig formatting intent.

## Phase 10 — Final Verification

- [ ] 60. `make build`
- [ ] 61. `./out/bin/with-stage2 check src/main.w`
- [ ] 62. `make smoke`
- [ ] 63. `make fixpoint`
- [ ] 64. Confirm all formatting test suites pass.
- [ ] 65. Confirm benchmark output is correct.
- [ ] 66. Confirm compiler source has zero `str ++ non-str` sites.
- [ ] 67. Confirm `++` is str-only and f-strings are the formatting surface.
