# With

With is a systems language with a self-hosted compiler.

The compiler is written in With and compiles itself. The repository includes a
frozen Zig bootstrap compiler (`bootstrap/`) as a historical artifact — it is
no longer used in the build pipeline.

## Requirements

- clang/LLVM toolchain available on PATH

## Build Flow (Staged)

The compiler follows a staged selfhost model. Each stage compiles the same
source (`src/main.w`) using the previous stage as the seed:

- Seed: `src/main` (checked-in binary) or a prior selfhost checkpoint
- Stage 1: selfhost compiler built from the seed
- Stage 2: selfhost compiler built by stage 1 (canonical compiler)
- Stage 3: selfhost compiler built by stage 2 (fixpoint verification)

**Fixpoint:** Stage 2 and Stage 3 produce byte-identical binaries, proving the
compiler is stable.

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
cc -I runtime hello.c runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_aarch64.s -o hello
```

## Test

Wave11 driver/unit regression suite:

```sh
./scripts/run_wave11_driver_unit_tests.sh
```

Fixpoint verification (stage2 == stage3):

```sh
./scripts/run_wave12_selfhost_fixpoint.sh
```

## Repo Layout

```text
src/                 self-hosted compiler (.w)
src/main             binary seed (fixpoint-verified selfhost checkpoint)
src/compiler/        Compilation-first architecture port layer
runtime/             C runtime support
lib/std/             standard library
test/cases/          self-hosted behavior tests
bootstrap/           historical Zig bootstrap compiler (frozen, unused)
bootstrap/test/cases/ legacy parser/codegen tests (used as test corpus)
```

## Troubleshooting

- `install: ... Operation not permitted` under `/usr/local`:
  use `PREFIX=$HOME/.local` or run `sudo make install`.
- `missing runtime/libwith_llvm_bridge.dylib`:
  keep `runtime/` adjacent to the `with` binary (the Makefile install targets do this).
- Stuck/hanging staged rebuilds on macOS external volumes:
  use `./scripts/rebuild_selfhost.sh stage2` (runs via `/tmp`).
