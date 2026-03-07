# With

With is a systems language with a self-hosted compiler.

This repository has two compiler implementations:
- `bootstrap/` (Zig): trusted bootstrap compiler
- `src/` (With): self-hosted compiler and backend

## Requirements

- Zig `0.15.x`
- clang/LLVM toolchain available on PATH

## Build Flow (Staged)

The compiler follows a staged selfhost model:

- Stage 0: `bootstrap/zig-out/bin/with` (emergency seed only)
- Stage 1: self-host compiler built from the current selfhost seed
- Stage 2: self-host compiler built by stage 1 (canonical compiler)

Use the Make targets:

```sh
make stage1
make stage2
```

`make build` runs through stage2 and refreshes `out/bin/with` from `out/bin/with-stage2`:

```sh
make build
```

For reliable rebuilds on macOS/external-volume setups, staging uses:

```sh
./scripts/rebuild_selfhost.sh stage2
```

This prefers an existing selfhost compiler (`WITH`, `WITH_SELFHOST_SEED`, `out/bin/with`, `out/bin/with-stage2`, `out/bin/with-stage1`, or `with` on PATH), runs it from `/tmp`, and writes logs to `.with/build/.stage*.log`.

Bootstrap is used only if no working selfhost seed can be found.

## Install

Preferred (no sudo, fish):

```sh
make install PREFIX=$HOME/.local
fish_add_path -g ~/.local/bin
set -Ux WITH $HOME/.local/bin/with
```

System-wide:

```sh
sudo make install
```

`make install` installs:

- stage2 self-host compiler as `with`
- runtime files into `$(BINDIR)/runtime`

One-time seed only (when no working `with` exists yet):

```sh
make install-bootstrap PREFIX=$HOME/.local
```

This installs the stage0 bootstrap compiler and its runtime only as a recovery seed. After seeding, use
`make install` so your active compiler returns to the stage2 self-host compiler.

## Use

Basic commands:

```sh
with check examples/hello.w
with build examples/hello.w
./examples/hello
with run examples/hello.w
```

Debug/dump commands:

```sh
with check --dump-tokens examples/hello.w
with check --dump-ast examples/hello.w
with check --dump-resolved examples/hello.w
with check --dump-typed examples/hello.w
with check --dump-mir examples/hello.w
with check --dump-async-mir examples/hello.w
```

C emission path:

```sh
with build --emit-c examples/hello.w -o hello.c
zig cc -target <triple> -I runtime hello.c runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_<arch>.s -o hello
```

## Test

Bootstrap harness tests:

```sh
./bootstrap/zig-out/bin/with test test/cases/
./bootstrap/zig-out/bin/with test bootstrap/test/cases/
```

Wave11 driver/unit regression suite:

```sh
./scripts/run_wave11_driver_unit_tests.sh
```

## Repo Layout

```text
bootstrap/           Zig bootstrap compiler
src/                 self-hosted compiler (.w)
src/compiler/        Zig-style architecture port layer (Compilation-first)
runtime/             C runtime support
test/cases/          self-hosted behavior tests
bootstrap/test/cases/ bootstrap parser/codegen tests
```

## Troubleshooting

- `install: ... Operation not permitted` under `/usr/local`:
  use `PREFIX=$HOME/.local` or run `sudo make install`.
- `missing runtime/libwith_llvm_bridge.dylib`:
  keep `runtime/` adjacent to the `with` binary (the Makefile install targets do this).
- Stuck/hanging staged rebuilds on macOS external volumes:
  use `./scripts/rebuild_selfhost.sh stage2` (runs via `/tmp`).
