# The With Programming Language

A systems programming language that compiles to native code via LLVM.
Fast, safe, and designed to feel less hostile than existing native languages.

[Specification](docs/with-specification.md) | [Contributing](CONTRIBUTING.md) | [Editor Support](docs/feature_plans/editor-support.md) | [Devlog](https://github.com/withlang-dev/with/discussions/185)

## Why With?

- **Performance:** Compiles to native machine code via LLVM. No runtime interpreter, no GC pauses. Suitable for games, AI infrastructure, embedded systems, and web services.

- **Safety:** Ownership-based memory model with no use-after-free, no double-free, and no data races — without lifetime annotations. Ownership is persistent, borrowing is ephemeral, long-lived relationships use handles.

- **Ergonomics:** Indentation-based scoping, type inference, f-string interpolation, first-class regex, `let ... else` for early returns, `with` blocks for scoped mutation, and seamless C interop via `c_import`. The common case should not require ceremony.

## What It Looks Like

```
print("Hello, World!")
```

```
var nr = 0
for line in file.read_lines("server.log"):
    nr += 1
    if line =~ /error (\d+)/:
        print(f"{nr}: {line}")
```

```
fn handle(req: Request) -> Response:
    let user = db.find_user(req.params.id) else:
        return Response.not_found()
    Response.json(user)
```

```
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
```

## Quick Start

Install the latest release on macOS arm64 or Linux x86_64:

```sh
curl -fsSL https://github.com/withlang-dev/with/releases/latest/download/install.sh | sh
```

Install the latest release on Windows x86_64 from PowerShell:

```powershell
irm https://github.com/withlang-dev/with/releases/latest/download/install.ps1 | iex
```

Or from `cmd.exe`:

```bat
curl.exe -L -o install.cmd https://github.com/withlang-dev/with/releases/latest/download/install.cmd
install.cmd
```

Inspect the installers before running them:

```sh
curl -fsSL https://github.com/withlang-dev/with/releases/latest/download/install.sh | less
```

```powershell
irm https://github.com/withlang-dev/with/releases/latest/download/install.ps1
```

The Unix installer writes `with` to `~/.local/bin` by default. The Windows
installer writes `with.exe` to `%USERPROFILE%\.local\bin` by default. Set
`WITH_INSTALL_DIR` to choose another directory.

Make sure the install directory is on your PATH, then run:

```sh
with run examples/hello.w
```

All release binaries are listed on the
[releases page](https://github.com/withlang-dev/with/releases).

## Building from Source

Requirements:

 * LLVM toolchain (default `/usr/local/llvm`, override with `LLVM_PREFIX`)
 * clang on PATH

The compiler is self-hosting. The build chain is `seed -> stage1 -> stage2`:

```sh
git clone https://github.com/withlang-dev/with.git
cd with
with build :seed        # download seed compiler (if `with` is not on PATH)
with build              # build the compiler
with build :test        # run test suite
```

Install to your PATH:

```sh
with build :install-user    # installs to ~/.local/bin/with
```

Release publishing uses the checklist in
[docs/with-release-runbook.md](docs/with-release-runbook.md).

### Fixpoint Verification

The compiler compiles itself. `with build :fixpoint` builds stage3 from stage2
and verifies they are byte-identical. If fixpoint breaks, the compiler has a
nondeterminism bug.

```sh
with build :fixpoint
```

### Debugging Compiler And Runtime Issues

For crashes, use `lldb` on the smallest reproducing command. For deep compiler
bugs, reduce the input and use the targeted MIR/debug tools before adding trace
prints:

```sh
./out/stage/bin/with-stage2 reduce repro.w --contains "panic" -- ./out/stage/bin/with-stage2 check {file}
./out/stage/bin/with-stage2 check repro.w --trace-place main:_1
./out/stage/bin/with-stage2 check repro.w --explain-mir-origin main:_1
./out/stage/bin/with-stage2 check repro.w --trace-ownership main:_1
./out/stage/bin/with-stage2 check repro.w --dump-drop-plan
./out/stage/bin/with-stage2 check repro.w --validate-all
with build :fixpoint-diff
```

For drop, lifetime, double-free, use-after-free, or leak bugs in With-allocated
memory, start with the native debug allocator:

```sh
./out/stage/bin/with-stage2 run --debug-alloc repro.w
./out/stage/bin/with-stage2 run --debug-alloc --debug-alloc-filter=non-root repro.w
./out/stage/bin/with-stage2 check repro.w --dump-drop-state
./out/stage/bin/with-stage2 check repro.w --dump-place-map
with build :debug-alloc-tests
```

The tools are documented in
[docs/deep-debugging-tools.md](docs/deep-debugging-tools.md) and
[docs/debug-allocator.md](docs/debug-allocator.md). Contributor workflow details
are in [CONTRIBUTING.md](CONTRIBUTING.md#debugging).

## Editor Support

The compiler includes a built-in language server (`with lsp`) with diagnostics,
go-to-definition, hover, and format-on-save. Setup instructions for VSCode,
Neovim, Vim, Emacs, Zed, and Helix are in [docs/feature_plans/editor-support.md](docs/feature_plans/editor-support.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build setup, architecture overview,
testing, and debugging instructions.

## License

With is distributed under the [MIT License](LICENSE).
