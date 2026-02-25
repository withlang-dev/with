# With

A systems programming language that wants you to have a good time.

No garbage collector. No lifetime annotations. No fighting the compiler for an hour to do something obvious. Memory safety, native performance, and code that reads like you'd explain it to a colleague.

```
async fn handle_signup(req: HttpRequest, db: &Database) -> Result[HttpResponse, ApiError] =
    let body = req.json[SignupRequest]() ?? return Err(.InvalidJson)

    if not body.email.is_valid() then
        return Err(.ValidationError("Invalid email format"))

    if db.find_user(body.email).await?.is_some() then
        return Err(.ValidationError("Email already exists"))

    let email = body.email
    let user = User { email, role: .Member, created: Instant.now() }

    db.insert(user).await?
    HttpResponse.json(201, "User created successfully")
```

## Status

Early development. The bootstrap compiler (written in Zig) can lex, parse, and dump ASTs for basic With programs.

## Prerequisites

- [Zig](https://ziglang.org/) 0.15+
- [LLVM](https://github.com/llvm/llvm-project/releases) 18+ (C API headers and static libraries)

### LLVM setup

Download a prebuilt release for your platform from the [LLVM releases page](https://github.com/llvm/llvm-project/releases) and install it:

```
# macOS ARM64 example (adjust version as needed)
tar xf LLVM-22.1.0-macOS-ARM64.tar.xz
sudo mv LLVM-22.1.0-macOS-ARM64 /usr/local/llvm
```

Add to your shell config:

```sh
# bash/zsh
export LLVM_HOME=/usr/local/llvm
export PATH="$LLVM_HOME/bin:$PATH"

# fish
set -gx LLVM_HOME /usr/local/llvm
fish_add_path $LLVM_HOME/bin
```

Verify: `llvm-config --version`

## Building

```
zig build
```

## Usage

```
# Parse and dump the AST
zig build run -- ast test/cases/hello.w

# Dump token stream
zig build run -- tokens test/cases/hello.w

# Show help
zig build run -- help
```

Or use the binary directly after building:

```
./zig-out/bin/with ast test/cases/hello.w
```

## Running tests

```
zig build test
```

## Project structure

```
src/
  main.zig          CLI entry point
  Driver.zig        Pipeline orchestration (lex -> parse -> ...)
  Lexer.zig         Tokenizer
  Token.zig         Token definitions
  Parser.zig        Recursive descent parser
  Ast.zig           AST node types
  render.zig        AST pretty-printer
  Diagnostic.zig    Structured error reporting
  Source.zig         Source file management
  Span.zig          Source location tracking
  InternPool.zig    String interning
test/
  cases/            .w source files for testing
  expected/         Snapshot expected outputs
docs/
  with-specification.md
  with-compiler-plan.md
  with-implementation-notes.md
examples/
  c-interop/        C FFI via c_import
  channels/         Channel-based concurrency
  ecs/              Entity component system
  json-parser/      JSON parser
  service/          Async HTTP service
```

## Documentation

- [Language Specification](docs/with-specification.md)
- [Compiler Plan](docs/with-compiler-plan.md)
- [Implementation Notes](docs/with-implementation-notes.md)
- [Migration Guide](docs/with-migration-guide.md)
