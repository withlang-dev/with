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
./with-stage1 build src/main.w -o .with/build/with-stage2
cp .with/build/with-stage2 ./with-stage2
```

## Test

Run both suites with the bootstrap test harness:

```sh
./bootstrap/zig-out/bin/with test test/cases/
./bootstrap/zig-out/bin/with test bootstrap/test/cases/
```

Then sanity-check the stage2 compiler binary:

```sh
./with-stage2 version
```

Or use Make targets for the full flow:

```sh
make test
```

## Repo Layout

```text
bootstrap/           Zig bootstrap compiler
src/                 self-hosted compiler (.w)
runtime/             C runtime support
test/cases/          self-hosted behavior tests
bootstrap/test/cases/bootstrap parser/codegen tests
```
