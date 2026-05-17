The With Programming Language
Published
May 11, 2026
•
14 min read
Eric Hartford
Eric Hartford
I make AI models like Dolphin and Samantha https://ko-fi.com/erichartford BTC 3ENBV6zdwyqieAXzZP2i3EjeZtVwEmAuo4 ETH 0xcac74542A7fF51E2fb03229A5d9D0717cB6d70C9
On this page

What With looks like
The language
Why it's called With
Why With exists
Python as the reference point
The ownership model
Ergonomics as a design constraint
The self-hosting milestone
What I'm aiming for
I'm Eric Hartford, creator of the Dolphin and Samantha open source AI models. After 25 years as a software engineer, I've ascended into the role of AI Scientist. And I'm building a programming language called With.

It's a systems programming language, and compiles to native machine code. Meant for performance-sensitive software: games, AI infrastructure, embedded systems, web services, native tools, and more.

But the point of With is not just to be fast. There are already fast languages.

The point is to make native programming feel less hostile.

What With looks like
Here is a complete With program that reads a file and prints every line containing an error, with line numbers:

var nr = 0
for line in file.read_lines("server.log"):
    nr += 1
    if line =~ /error (\d+)/:
        print(f"{nr}: {line}")

Here is a small HTTP handler:

fn handle(req: Request) -> Response:
    let user = db.find_user(req.params.id) else:
        return Response.not_found()
    Response.json(user)

find_user returns Option[User]. The let ... else binding unwraps the Some case and runs the else block on None, so user is a plain User after the binding. It is the common "look it up or return early" pattern without a nested match.

Here is a struct with scoped mutation:

@[derive(Default)]
type Config {
    timeout: i32,
    retries: i32,
    verbose: bool,
}

let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3

The with ... as mut block creates a mutable binding, lets you configure it, and returns the finished value. The last statement is an assignment, so the block returns c automatically.

Here is how you pull in a C library and use it:

use c_import("raylib.h")

fn main:
    InitWindow(800, 600, "hello from With")
    while not WindowShouldClose():
        BeginDrawing()
        defer: EndDrawing()
        ClearBackground(RAYWHITE)
        DrawText("hello world", 190, 200, 20, LIGHTGRAY)
    CloseWindow()

That is not pseudocode. with get c.raylib downloads raylib from Conan, adds it to your project, and c_import makes the headers available. You call C functions directly. defer ensures EndDrawing() runs at the end of each loop iteration, pairing it with BeginDrawing().

And here is regex, which works the way Perl programmers expect:

let re = /^(?P<key>\w+)\s*=\s*(?P<value>.+)$/

for line in stdin.lines():
    if line =~ re:
        print(f"{\(key} => {\)value}")

Regex literals are first-class values. =~ performs the match and binds \(key and \)value in the if body. The regex engine is PCRE2, migrated from roughly 73,000 lines of C using With's own C migration tool and passing the upstream PCRE2 test suite.

The language
With is imperative, statically typed, compiled via LLVM, and uses indentation-based scoping. It has three interchangeable body forms:

// Indented colon
if x > 0:
    process(x)

// Braced
if x > 0 {
    process(x)
}

// Inline colon
if x > 0: process(x)

Switch freely between them. Use whichever fits.

Variables are let (immutable) or var (mutable). Types are inferred when obvious, explicit when needed:

let name = "alice"            // str
var count = 0                 // i32
let scores: Vec[f64] = Vec.new()

No implicit numeric casts. Explicit as for all conversions.

Functions declare their types:

fn clamp(x: i32, lo: i32, hi: i32) -> i32:
    if x < lo: return lo
    if x > hi: return hi
    x

Pattern matching with enums:

enum Shape:
    Circle(f64)
    Rect(f64, f64)

fn area(s: Shape) -> f64:
    match s:
        .Circle(r) => PI * r * r
        .Rect(w, h) => w * h

Error handling uses Result and Option with else for early returns:

fn load_config(path: str) -> Result[Config, Error]:
    let text = file.read(path) else return Err(.FileNotFound)
    let parsed = parse_toml(text) else return Err(.ParseError)
    Ok(Config.from(parsed))

Async with structured concurrency:

async fn fetch_all(urls: Vec[str]) -> Vec[Response]:
    async scope s =>
        let tasks = urls.iter()
            |> map(url => s.track(http.get(url)))
            |> collect[Vec]()
        tasks |> map(t => t.await) |> collect()

async scope creates a structured scope: all tracked tasks are joined before the scope exits. Cancellation propagates automatically.

Generics:

fn max[T: Comparable](a: T, b: T) -> T:
    if a > b: a else: b

Defer for resource cleanup:

fn process_file(path: str):
    let f = file.open(path)
    defer: f.close()
    for line in f.lines():
        handle(line)

That is not all of it. But it is enough to see the shape: the syntax stays out of your way, the types are present but not noisy, and the constructs do what you expect them to do.

Why it's called With
The name comes from the core abstraction of the language: working with data through scoped access.

The with keyword is not decorative. It is the language's signature construct:

// Guarded resource access
with lock.read() as data:
    process(data)

// Scoped mutation (the Config example from above)
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3

// Record update
let moved = { entity with position: new_pos }

These are all doing different things, but they share the same idea: name the thing you are working with, limit the scope where that access exists, and let the compiler enforce the boundary.

Instead of asking the programmer to annotate how long a reference lives, With tries to make the scope visible in the structure of the code. You say what you are working with. You say where you are working with it. The compiler handles the lifetime consequences.

The name also fits the broader attitude of the project. With is meant to work with the programmer, with C libraries, with existing hardware, and with the way people actually build software.

Why With exists
The original motivation came from AI.

The modern AI stack is much heavier than it needs to be. Python won AI for understandable reasons. It is easy to use, the libraries accumulated around it, and eventually the ecosystem became the reason to keep using it. Python has a very good workflow for experimentation.

But Python plus PyTorch feels like the wrong foundation for the future of AI.

The performance-critical parts are not really Python. They are native libraries underneath Python, wrapped in layers of orchestration, packaging, runtime assumptions, and hardware-specific complexity. The stack works, but it is bloated.

A lot of modern AI code is shaped by the hardware path it expects. CUDA has influenced the ecosystem deeply. Even when the source code looks portable, the surrounding assumptions often are not. Drivers, kernels, packaging, accelerators, fallbacks, deployment targets. Too much of that leaks upward into the way people write and ship ML systems.

I wanted a different model. I wanted AI and ML code to describe the computation, not the preferred hardware. Switching from GPU to CPU should not require rewriting the program. It should require changing configuration. I am also building an ML framework on top of With called Crux, but that is its own story for another time.

Once I started thinking about what that framework needed underneath it, the language question became unavoidable. I did not want to build that future on top of Python glue forever. I wanted a native foundation: fast, portable, direct, and still pleasant to use.

That became With.

Python as the reference point
Python is important to this project because Python got something right.

People often talk about Python as if its popularity is just a historical accident. It is partly historical, but that is not the whole story. Python has a good sense of proportion. You can open a file and write useful code immediately. You can explore. You can test small ideas. You can glue libraries together without turning every program into an architecture project.

If With is going to be a serious alternative for Python programmers, especially in AI and data-heavy work, it cannot only be good at compiling finished programs. It also has to be good at exploration.

That is why with repl and with notebook are release gates.

With is incomplete without them.

A REPL and notebook are not side projects. They are part of the language's identity. They are how people think through problems, especially in AI. They let you move from experiment to script to real program without losing the thread.

Start in a REPL. Move to a notebook. Turn the idea into a script. Grow it into a program. Keep the same language.

The ownership model
Every systems language has to make a decision about ownership.

With's decision is simple:

Ownership is persistent. Borrowing is ephemeral. Relationships are handles.

That is the core bargain of the language. Values have exactly one owner. References exist only in local scope. Long-lived references use typed indices, handles, or IDs instead of raw pointers or stored borrows.

In practical terms, this means safe With does not allow references to be stored inside structs.

At first, that may sound restrictive. If you are coming from Rust or C++, you may expect to build long-lived structures that contain references into other structures.

With deliberately chooses not to support that in safe code.

The reason is that most lifetime complexity comes from storing references in data structures. Once a struct can contain a reference, the compiler has to know how long that reference remains valid. That lifetime starts propagating through APIs, generics, iterators, trait bounds, async state, and every abstraction that touches the type.

With avoids that entirely.

References are for local use. They can be function parameters, local bindings, short-lived return values, views, guards, and temporary access patterns. But they do not become the long-lived shape of your data model.

If something needs to persist, you own it, or you store a handle.

// Not this — stored references create lifetime complexity
type Lexer {
    source: &str  // not allowed in safe With
}

// This — owned data or handles
type Lexer {
    source: str       // owned copy
    // or
    source_id: SourceId   // handle into a source table
}

That gives up some expressiveness. It is a real tradeoff.

You cannot write every borrow-heavy pattern that Rust can express. Borrow-based lazy iterators that escape their scope are not the default path. Parsers that want to keep views into source text store offsets into an owned buffer. Graphs, scene trees, ECS worlds, and resource systems use handles.

But in exchange, With has no lifetime annotations. None. The language preserves compile-time safety — no use-after-free, no double-free, no data races — without making ordinary code carry lifetime machinery in its type signatures.

That tradeoff also pushes programs toward data-oriented design, which turns out to be the architecture you want anyway for games, servers, embedded systems, and high-performance computing.

I do not want With to be maximally expressive for every possible borrowing shape. I want it to make the healthier architecture the easiest architecture.

Ergonomics as a design constraint
A lot of systems languages treat ergonomics as something to add after the serious parts are done. First you design the type system, memory model, compiler, and runtime. Then later, maybe, you sand down the rough edges.

With comes from the opposite instinct.

Ergonomics are not polish. They are part of the language's identity.

That does not mean the formal parts are unimportant. The compiler still needs a coherent model. The type system needs to make sense. The semantics need to be predictable. If the language is going to compile to native code and operate close to the machine, the machinery underneath has to be serious.

But that machinery exists to serve the programmer.

A few concrete examples of what this means in practice.

Implicit main. Top-level statements just run. You do not need fn main: for a script:

print("hello")

That compiles and runs. The compiler wraps it for you.

CLI one-liners. The same implicit-main feature enables shell usage:

seq 100 | with -n 'if line =~ /^[0-9]$/: print(line)'
cat names.txt | with -p 'line = line.upper()'

-n loops over stdin lines. -p loops and prints. -e runs arbitrary code. These are compiled programs, not interpreted scripts.

String interpolation. f-strings, like Python:

print(f"found {count} errors in {elapsed:.2}s")

C interop without friction. with get c.raylib fetches a library. c_import("header.h") makes it available. No bindings, no wrappers, no FFI ceremony.

Regex as a language feature. /pattern/flags literals, =~ operator, \(1/\)name capture bindings. Not a library afterthought.

These are not separate conveniences. They are a unified design philosophy: the common case should not require ceremony.

The self-hosting milestone
With is self-hosting. The compiler is written in With.

The build process runs a three-stage bootstrap: stage 1 compiles stage 2, stage 2 compiles stage 3, and stages 2 and 3 must produce byte-identical output. That fixpoint verification runs on every change. If the compiler cannot compile itself deterministically, something is wrong.

The compiler is also a C migration tool. with migrate mechanically translates C codebases to With. The current regex engine is PCRE2 — roughly 73,000 lines of C, auto-migrated to ~160,000 lines of With, passing the upstream PCRE2 test suite. All translation bugs were fixed in the migrator itself, not by hand-patching generated code.

These are not just engineering milestones. They are proof that the language works for real software. A self-hosting compiler and a migrated PCRE2 regex engine are not toy programs.

What I'm aiming for
The scope of With is broad because the problems I care about are broad.

I want it to be useful for AI and ML. Not just as a training framework language, but as the foundation for the entire stack from data loading to model serving, without the Python-to-C++ boundary that currently defines the field.

I want it to be good for games. A game touches everything: native performance, quick iteration, graphics, input, assets, audio, timing, C libraries, and code that needs to be low-level in one place and expressive in another. Games are the best stress test for a language because they demand the whole system work together.

I want it to work for embedded targets. Dense arrays, predictable ownership, no hidden allocations, direct hardware access.

I want it to be capable enough for kernel modules. Not as a primary use case, but as a proof of how low it can go.

I want it to be practical for web development and native tools. Fast executables, simple deployment, strong string handling, good regex, easy C interop for database drivers and crypto libraries.

The common thread is real: native code, good ergonomics, strong interop, and a development experience that does not make simple things feel ceremonial.

I am not trying to make a language that only wins on one axis. I am trying to make a language that feels good across the whole path from experiment to production.

Start in a notebook. Try an idea in the REPL. Write a one-liner. Turn it into a script. Grow it into a program. Pull in C libraries when you need them. Compile to native code. Run on the hardware you have. Keep the code readable.

That is the path I want With to support.

A systems language can be fast and still feel humane. A language can expose low-level control without making every program start at the lowest level. C interop can be ordinary. Notebooks and REPLs belong in a native language. The compiler should carry more of the complexity so the programmer can stay closer to the problem they are actually solving.

With is my attempt to build a better foundation: native, ergonomic, interoperable, and hardware-neutral where it matters.

I hope you enjoy using With as much as I enjoyed making it. I am looking forward to your feedback.

With is pre-release, not 1.0.0 yet. The language semantics and implementation are still shifting. But it's a good time to get involved with this MIT licensed open source project.

With's github repository: https://github.com/withlang-dev/with
And my devlog: https://github.com/withlang-dev/with/discussions/185