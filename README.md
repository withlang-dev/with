# With

With is a systems language with a self-hosted compiler.

This repository has two compiler implementations:
- `bootstrap/` (Zig): trusted bootstrap compiler
- `src/` (With): self-hosted compiler and backend

## Requirements

- Zig `0.15.x`
- clang/LLVM toolchain available on PATH

## Build Flow

1. Build bootstrap compiler:

```sh
cd bootstrap
zig build
cd ..
```

2. Stage 1 (bootstrap compiles self-hosted compiler):

```sh
./bootstrap/zig-out/bin/with build src/main.w
cp .with/build/main ./with-stage1
```

3. Stage 2 (self-hosted compiler compiles itself):

```sh
cp ./with-stage1 /tmp/with-stage1-local
chmod +x /tmp/with-stage1-local
/tmp/with-stage1-local build src/main.w
cp .with/build/main ./with-stage2
```

For a reliable end-to-end rebuild on macOS/external-volume setups, use:

```sh
./scripts/rebuild_selfhost.sh stage2
```

This runs compiler binaries from `/tmp` and writes logs to `.with/build/.stage*.log`.

## Test

Run both suites with the bootstrap test harness:

```sh
./bootstrap/zig-out/bin/with test test/cases/
./bootstrap/zig-out/bin/with test bootstrap/test/cases/
```

Then sanity-check the stage2 compiler binary:

```sh
cp ./with-stage2 /tmp/with-stage2-check
/tmp/with-stage2-check version
```

Or use Make targets for the full flow:

```sh
make test
```

Run the Stage-0 bootstrap gate (bootstrap -> stage2 rebuild) with:

```sh
make gate-stage0
```

## Repo Layout

```text
bootstrap/           Zig bootstrap compiler
src/                 self-hosted compiler (.w)
src/compiler/        Zig-style architecture port layer (Compilation-first)
runtime/             C runtime support
test/cases/          self-hosted behavior tests
bootstrap/test/cases/bootstrap parser/codegen tests
```
