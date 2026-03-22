# With

With is a systems language with a self-hosted compiler.

The compiler is written in With and compiles itself. The repository includes a
frozen Zig bootstrap compiler (`bootstrap/`) as a historical artifact — it is
no longer used in the build pipeline.

## Requirements

- LLVM toolchain (default: `/usr/local/llvm`, override with `LLVM_PREFIX`)
- clang available on PATH (for linking user programs)
- Zig (optional, for cross-compilation)

## Build

The Makefile is the primary build interface. Normal development should go
through `make`, not through ad hoc shell scripts.

The self-host chain is:

```text
seed → stage1 → stage2 → stage3
```

Common targets:

```sh
make stage1        # build stage1 only
make stage2        # build stage2 only
make build         # alias for stage2, also refreshes out/bin/with
make stage3        # build stage3 only
make fixpoint      # verify stage2 == stage3
make test          # run test suite with stage2
make smoke         # quick compiler smoke check
```

The seed compiler is resolved from `WITH` env var, `with` on PATH, or
a downloaded seed binary:

```sh
make build                           # uses `with` on PATH
make seed && make build              # downloads seed from GitHub releases
WITH=~/other/with make build         # uses explicit binary
```

`src/main` is a local downloaded seed binary. It is gitignored and must never
be committed or pushed.

`out/bin/with-stage2` is the canonical built compiler in the workspace, and
`out/bin/with` is a copy of it for convenience. `make fixpoint` builds stage3
from stage2 and verifies they are byte-identical.

## Install

```sh
make install-user                    # installs to ~/.local/bin/with
make install PREFIX=$HOME/.local     # explicit local prefix install
sudo make install                    # installs to /usr/local/bin/with
```

`make build` does not install to your PATH. Installing is a separate step.

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
make fixpoint
```

## Repo Layout

```text
src/                 self-hosted compiler (.w)
src/main             local seed binary (gitignored; download via `make seed`)
src/compiler/        Compilation-first architecture port layer
runtime/             C runtime source (.c, .h, .s)
lib/std/             standard library (.w)
test/cases/          behavior tests
out/                 all build output (gitignored)
  bin/               compiler binaries
  lib/               compiled runtime objects (.o), LLVM link config
  log/               build logs
bootstrap/           historical Zig bootstrap compiler (frozen, unused)
```

## Troubleshooting

- `install: ... Operation not permitted` under `/usr/local`:
  use `make install-user`, `PREFIX=$HOME/.local`, or run `sudo make install`.
- `no LLVM bridge available`: install LLVM at `/usr/local/llvm` or set `LLVM_PREFIX`.
  The compiler statically links LLVM — no dynamic library needed at runtime.
- Need only the staged compiler rebuild:
  use `make stage2` for stage2 only, or `make fixpoint` for stage2 plus stage3 verification.
- Legacy scripts that say `./scripts/rebuild_selfhost.sh ...`:
  that script is now only a compatibility wrapper around `make stage1|stage2|stage3`.
