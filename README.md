# With

With is a systems language with a self-hosted compiler.

The compiler is written in With and compiles itself. The repository includes a
frozen Zig bootstrap compiler (`bootstrap/`) as a historical artifact — it is
no longer used in the build pipeline.

## Requirements

- clang/LLVM toolchain available on PATH

## Build

The compiler compiles itself in two stages:

```sh
make build         # seed → stage1 → stage2
make fixpoint      # verify stage2 == stage3
make test          # run test suite
make install       # install to ~/.local/bin (or /usr/local/bin)
```

The seed compiler is resolved from `WITH` env var or `with` on PATH:

```sh
make build                           # uses `with` on PATH
WITH=./src/main make build           # uses checked-in binary seed
WITH=~/other/with make build         # uses explicit binary
```

**How it works:** The seed compiles `src/main.w` → stage1, then stage1
compiles `src/main.w` → stage2. Stage2 is the canonical compiler.
Stage2 and stage3 produce byte-identical binaries (fixpoint).

## Install

```sh
make install PREFIX=$HOME/.local     # installs to ~/.local/bin/with
sudo make install                    # installs to /usr/local/bin/with
```

For fish shell:

```sh
fish_add_path -g ~/.local/bin
```

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
runtime/             C runtime source (.c, .h, .s)
lib/std/             standard library (.w)
test/cases/          behavior tests
out/                 all build output (gitignored)
  bin/               compiler binaries
  lib/               compiled runtime (.o, .dylib)
  log/               build logs
bootstrap/           historical Zig bootstrap compiler (frozen, unused)
```

## Troubleshooting

- `install: ... Operation not permitted` under `/usr/local`:
  use `PREFIX=$HOME/.local` or run `sudo make install`.
- `missing runtime/libwith_llvm_bridge.dylib`:
  keep `runtime/` adjacent to the `with` binary (the Makefile install targets do this).
- Stuck/hanging staged rebuilds on macOS external volumes:
  use `./scripts/rebuild_selfhost.sh stage2` (runs via `/tmp`).
