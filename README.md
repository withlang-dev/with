# With

With is a systems language focused on memory safety, ownership, and low-level control without a GC.

This repository contains the Zig bootstrap compiler, runtime, standard library modules, tooling commands, and phase-based test suites.

## Status

- The bootstrap compiler is actively developed and implements broad Phase 0-6 functionality.
- The command-line tool supports compile/run/check/test plus tooling (`fmt`, `doc`, `lsp`, `repl`, `migrate`).
- The detailed feature checklist lives in `docs/test_checklist.md`.

## Requirements

- Zig `0.15.2` (or compatible `0.15.x`)
- LLVM with C API + clang toolchain available

The build expects `LLVM_PREFIX` (defaults to `/usr/local/llvm`) and uses:

- `${LLVM_PREFIX}/bin/clang++`
- `${LLVM_PREFIX}/include`
- `${LLVM_PREFIX}/lib`

Example:

```sh
export LLVM_PREFIX=/usr/local/llvm
zig build
```

## Build

```sh
zig build
```

Compiler binary:

```sh
./zig-out/bin/with
```

## CLI Quick Reference

```sh
with build <file.w>                     # Compile to native binary
with run <file.w>                       # Compile + run
with check <file.w>                     # Parse + type-check
with test [path] [--update]             # Built-in harness runner
with fmt <file.w>                       # Format to stdout
with doc <file.w>                       # Generate docs (markdown to stdout)
with repl                               # Interactive REPL
with lsp                                # LSP server over stdio
with migrate <lang> <path> [--check|--diff]  # rust|zig|swift to .w
with ir <file.w>                        # Dump LLVM IR
with ast <file.w>                       # Dump AST
with tokens <file.w>                    # Dump lexer tokens
with version
with help
```

## Testing

Unit tests:

```sh
zig build test
```

Phase suites (script-based):

```sh
bash test/run_phase6_tests.sh
```

Run every phase script:

```sh
for s in test/run_phase*.sh; do bash "$s"; done
```

## Repository Layout

```text
src/
  main.zig              CLI entrypoint
  Driver.zig            Compiler pipeline orchestration
  Lexer.zig             Tokenizer
  Parser.zig            Parser
  Sema.zig              Semantic analysis
  Codegen.zig           LLVM IR codegen
  Lsp.zig               Language server
  Migrate.zig           Source migration tooling
  Mir.zig               MIR scaffolding
  MirOpt.zig            MIR optimization passes
runtime/
  fiber.c
  fiber_asm_aarch64.s
  helpers.c
lib/std/
  *.w                   Standard library modules
test/
  cases/                Runtime/behavior examples
  run_phase*_tests.sh   Phase and feature suites
docs/
  with-specification.md
  with-compiler-plan.md
  with-implementation-notes.md
  with-migration-guide.md
  test_checklist.md
```

## Documentation

- Language spec: `docs/with-specification.md`
- Compiler plan: `docs/with-compiler-plan.md`
- Implementation notes: `docs/with-implementation-notes.md`
- Migration guide: `docs/with-migration-guide.md`
- Test checklist: `docs/test_checklist.md`
