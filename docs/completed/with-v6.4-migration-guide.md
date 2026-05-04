# With v6.4 Migration Guide — Implementation Checklist

Spec changes: Section 18.7 "Freestanding Mode (`no_std`)" + Section 25.99 test cases.

## Files to Inspect

- [x] `src/main.zig` — Add `--no-std` and `--alloc` CLI flags, pass to Driver; fix `sourceHasMainFn` for With syntax; add `// FLAGS:` test directive support
- [x] `src/Driver.zig` — Add `no_std: bool` and `alloc: bool` fields, propagate to Sema/Codegen
- [x] `src/Parser.zig` — Parse new annotations: `@[panic_handler]`, `@[entry]`, `@[no_main]`
- [x] `src/Ast.zig` — Add annotation flags to FnDecl: `is_panic_handler`, `is_entry`, `is_no_main`
- [x] `src/Sema.zig` — Reject std-dependent builtins in no_std mode (println, print, Vec, HashMap, HashSet, Box, Channel, spawn, async fn); `isStdOnlyBuiltin()` helper
- [x] `src/Codegen.zig` — Use `@[entry]` as entry point (`effective_name` override in `declareFunction`); fix match arm divergence detection for intermediate overflow-check blocks
- [x] `test/cases/no_std_core_types.w` — POSITIVE: core types work in no_std mode
- [x] `test/cases/no_std_reject_println.w` — NEGATIVE: println rejected in no_std
- [x] `test/cases/no_std_reject_vec.w` — NEGATIVE: Vec rejected in no_std
- [x] `test/cases/no_std_entry_point.w` — POSITIVE: @[entry] works as alternative entry
- [x] `docs/with-migration-guide.md` — Add no_std section under Universal Patterns

## Additional fixes (regressions from overflow checking)

- [x] `lib/std/hash.w` — FNV hash `combine()` uses wrapping multiply `*%` (intentional overflow)
- [x] `src/Codegen.zig` — Match arm divergence detection: use `LLVMGetFirstUse` to distinguish dead blocks from live intermediate blocks created by overflow checks
