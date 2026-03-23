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

- [ ] 7. Add `NK_FSTRING` and `NK_FSTRING_SPEC` node kind constants to `src/Ast.w`.
      Add `FSTR_SEG_LITERAL = 0` and `FSTR_SEG_EXPR = 1` segment-kind constants.
- [ ] 8. Update AST name tables, dump/debug utilities, and structural validation to
      handle the new node kinds.
- [ ] 9. In `src/Parser.w`, replace `desugar_interpolated_string` / `interp_concat`
      with structured `NK_FSTRING` emission. Emit `FSTR_SEG_LITERAL` for text
      segments and `FSTR_SEG_EXPR` for interpolation holes. Preserve source spans.
- [ ] 10. Parse interpolation holes as `expr` plus optional `:spec`. Split on
      top-level `:` only, ignoring nested `()`, `[]`, `{}`, and string literals.
      Preserve `{{`/`}}` escaped-brace behavior.
- [ ] 11. Implement `parse_format_spec`: parse the spec grammar
      `[[fill]align][sign]['#']['0'][width]['.' precision][mode]` into
      `NK_FSTRING_SPEC` packed fields (see `format-design.md` §6.1). Reject
      malformed specs with errors.
- [ ] 12. Add interim codegen fallback: when codegen encounters `NK_FSTRING`,
      desugar it back to the same `OP_CONCAT` chain so the compiler can still
      rebuild itself. Do not remove old concat codegen yet.
- [ ] 13. Verify: `make build && ./out/bin/with-stage2 check src/main.w`.
- [ ] 14. Add parser-focused tests: bare holes `f"{x}"`, escaped braces `f"{{}}"`
      , nested delimiters `f"{a[i]}"`, colon in expressions `f"{m.get(k)}"`,
      format specs `f"{x:08x}"`, and malformed spec errors.

## Phase 2 — Semantic Analysis

- [ ] 15. Add `check_fstring` in `src/Sema.w`: type-check each `FSTR_SEG_EXPR`
      segment, set result type of `NK_FSTRING` to `ty_str`.
- [ ] 16. Implement mode/type compatibility matrix: `d/x/X/b/o` for integers,
      `f/e/g` for floats, `s` for strings, `?` for all types. Reject invalid
      combinations with precise diagnostics pointing at the spec.
- [ ] 17. Implement field/type compatibility matrix: width/fill/align for all,
      precision for floats and strings only, `#` for integer hex/bin/oct only,
      sign for numbers only. Encode default-mode rules (integers→`d`, floats→`g`,
      strings→`s`, precision-without-mode→`f`).
- [ ] 18. Enforce bare-display rules: `{struct_expr}` without `:?` is a
      compile-time error with hint.
- [ ] 19. Verify: `make build && ./out/bin/with-stage2 check src/main.w`.
- [ ] 20. Add sema tests for every valid/invalid matrix cell: integer modes, float
      modes, string modes, bool restrictions, precision on integers (error),
      sign on strings (error), `#` on floats (error).

## Phase 3 — Bootstrap Bridge

- [ ] 21. Ensure the interim codegen fallback from task 12 produces correct output
      for all f-strings used in the compiler source. Test: `make build && make smoke`.
- [ ] 22. Build a fresh stage2 that understands the new `NK_FSTRING` AST and sema
      model. Install it as seed (`make install-user` or copy to `src/main`).
- [ ] 23. Verify: `make build && make smoke && ./out/bin/with-stage2 check src/main.w`.

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
