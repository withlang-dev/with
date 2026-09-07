# Self-Hosted Compiler Architecture (Zig-Port Shape)

This directory ports Zig's top-level compiler architecture shape into With,
while preserving current compiler behavior.

## Zig-shaped boundaries now in `src/compiler/`

- `Compilation.w`:
  orchestration root (equivalent role to Zig `Compilation`).
- `Compilation/Config.w`:
  normalized compiler settings (equivalent role to Zig `Compilation.Config`).
- `Zcu.w`:
  canonical compilation-unit state (`InternPool`, diagnostics, import/source context).
- `Frontend.w`:
  lex/parse/import/sema pipeline stage.
- `Backend.w`:
  LLVM codegen emission stage wrapper.
- `Link.w`:
  linker/runtime-bridge policy and command construction.

`src/Compilation.w` is now a compatibility shim that re-exports
`compiler.Compilation` so existing `use Compilation` call sites continue to work.

## Current migration state

- CLI (`src/main.w`) runs through `Compilation`.
- Pipeline state ownership moved out of `Driver` and into `Compilation + Zcu`.
- Existing heavy implementations are still reused:
  `Sema` and `Codegen` remain the engines behind frontend/backend wrappers.
- `Driver` remains in-tree for compatibility, but no longer defines the primary
  architecture path.

## Next architecture steps

1. Introduce explicit AIR/MIR stage ownership under `src/compiler/`.
2. Move semantic type truth into a single canonical table attached to `Zcu`.
3. Remove duplicate type reconstruction in codegen, using canonical IDs only.
4. Continue shrinking `Driver` to a legacy adapter, then retire it.
