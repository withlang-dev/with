# The With Programming Language

A systems programming language that compiles to native code via LLVM.
Fast, safe, and designed to feel less hostile than existing native languages.

[Specification](docs/with-specification.md) | [Contributing](CONTRIBUTING.md) | [Editor Support](docs/editor-support.md) | [Devlog](https://github.com/withlang-dev/with/discussions/185)

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

Install the latest Darwin arm64 binary:

```sh
mkdir -p ~/.local/bin && \
curl -fL https://github.com/withlang-dev/with/releases/latest/download/with-darwin-aarch64 -o ~/.local/bin/with && \
chmod +x ~/.local/bin/with && \
~/.local/bin/with version
```

Make sure `~/.local/bin` is on your PATH, then run:

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

Release publishing uses the checklist in [docs/release.md](docs/release.md).

### Fixpoint Verification

The compiler compiles itself. `with build :fixpoint` builds stage3 from stage2
and verifies they are byte-identical. If fixpoint breaks, the compiler has a
nondeterminism bug.

```sh
with build :fixpoint
```

## Editor Support

The compiler includes a built-in language server (`with lsp`) with diagnostics,
go-to-definition, hover, and format-on-save. Setup instructions for VSCode,
Neovim, Vim, Emacs, Zed, and Helix are in [docs/editor-support.md](docs/editor-support.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for build setup, architecture overview,
testing, and debugging instructions.

## License

With is distributed under the [MIT License](LICENSE).
