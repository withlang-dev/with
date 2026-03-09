# What's With, and Why?

There's a moment every Rust developer knows. You're building something real — a web server, a game engine, a database wrapper — and the code is *working*. The types are right, the ownership is clear, the performance is there. And then you need to store a reference in a struct.

Suddenly you're in lifetime territory. `'a` appears on one signature, then two, then five. You add `where` clauses. You meet `Pin<Box<dyn Future<Output = Result<T, E>> + Send + 'static>>`. You restructure your entire program to satisfy the borrow checker on a pattern that is obviously safe, that you could write in thirty seconds in Go or Python, that any experienced programmer can see is fine.

You spend an hour. You get it to compile. You look at what you've written and think: *this isn't what I meant.*

With is for that moment.

---

## The Pitch

With is a systems programming language — no garbage collector, no runtime overhead, compiled to native code. It has compile-time memory safety: use-after-free, double-free, and data races are caught before your program runs. It has algebraic data types, pattern matching, generics, traits, and async/await.

It does not have lifetime annotations.

```
async fn handle_signup(req: HttpRequest, db: &Database) -> Result[HttpResponse, ApiError]:
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

No `Ok(())`. No `.to_owned()` on every string. No `'a` anywhere. No `unsafe`. No explicit memory management. Fully statically typed, native-compiled, memory-safe.

It reads like Python. It runs like C.

## The Idea

Most lifetime complexity in Rust comes from one thing: storing references in structs. Once you allow `struct Lexer<'a> { source: &'a str }`, you need lifetime annotations on the struct, on every function that touches the struct, on every function that touches *those* functions. The annotations cascade.

With makes a different trade: **references cannot be stored in structs.** They exist as function parameters, local variables, and return values. They're ephemeral — they live for a scope, then they're gone. No annotations needed, because the compiler can see the whole picture from the function body alone.

This isn't a hack. It's a design philosophy. When you can't store references, you naturally reach for patterns that are better anyway: handles into arenas, typed indices into pools, `Arc` for shared ownership, `with` blocks for scoped access. These are the patterns that experienced systems programmers use by choice — data-oriented design, cache-friendly layouts, clear ownership. With makes them the path of least resistance instead of the fallback when the borrow checker gets angry.

The 90/10 rule applies here. Ninety percent of the code most people write never needs to store a reference in a struct. With makes that ninety percent effortless. The remaining ten percent uses handles, arenas, and — when you really need it — `unsafe`. No shame, no ceremony.

## What Rust Got Right

Let's be clear: Rust is a remarkable achievement. It proved that compile-time memory safety without a garbage collector is possible, practical, and worth the effort. Every systems language that comes after Rust benefits from that proof.

With doesn't exist because Rust is bad. With exists because Rust's safety model carries costs that many projects don't need to pay. Lifetime annotations are the cost of maximum generality — the ability to store references anywhere, return borrowing iterators, build intrusive linked lists in safe code. That generality is powerful. It's also the reason people bounce off Rust.

The question With asks is: *what if we traded that generality for simplicity?*

## The `with` Keyword

The language is named after its central construct. `with` means "access this value within this scope." It's the language's answer to lifetimes: instead of annotating how long a reference lives, you state what you're working with and let the scope handle the rest.

It appears in four forms:

**Guarded access** — when data lives behind a lock:

```
with lock.read() as data:
    data.iter() |> filter(it.active) |> count()
```

The lock is held for exactly the block. The compiler knows the type implements `Scoped`, dispatches through the guard automatically. No keywords, no ceremony — the type tells the compiler everything.

**Builder pattern** — when you're configuring something:

```
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
    c.verbose = true
```

Mutation is visually contained. Nothing outside the block sees the intermediate state.

**Scoped binding** — when you need a name for a temporary:

```
let damage = with calculate_armor_reduction(attacker, defender) as reduction:
    base_damage * (1.0 - reduction) + bonus_damage
```

**Record update** — functional transformation of data:

```
let moved = { entity with position: new_pos }
```

In a typical With codebase, you see `with` everywhere. It's how you interact with guarded data, configure objects, name intermediates, and transform records. It replaces lifetimes, builders, and a surprising number of temporary variables.

## Async That Doesn't Hurt

With's async model is fibers — lightweight threads with real stacks. When you write `async fn`, the runtime spawns a fiber. When you write `.await`, the fiber suspends. That's it.

Because fibers have real stacks, references across `await` points just work. No `Pin`. No `Unpin`. No `Future`. No `Poll`. These concepts don't exist in With.

```
async fn process(data: &mut Vec[i32]):
    let first = &data[0]
    some_io().await           // fiber suspends; reference is fine
    println(first)            // safe to use
```

In Rust, this requires `Pin<&mut Self>` because the Future is a struct and references into it break when the struct moves. In With, the fiber stack doesn't move. Problem solved.

Even better: `.await` works inside standard iterator closures.

```
let results = urls.iter()
    |> map(|url| fetch(url).await)
    |> filter(|r| r.is_ok())
    |> collect[Vec]()
```

This is impossible in Rust without `Stream`, `futures::join_all`, or rewriting to manual loops. In With, synchronous iteration and async functions compose freely. No colored functions. No trait bounds that infect everything. Just code that does what it says.

## C Interop on Day One

A systems language that can't call C libraries isn't a systems language. With treats C interop as a first-class feature, not an afterthought:

```
use c_import("SDL2/SDL.h", link: "SDL2")
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    var db: *mut sqlite3 = null
    sqlite3_open(c":memory:".ptr, &mut db)
    defer sqlite3_close(db)
```

`c_import` reads C headers at compile time, parses them, and makes every declaration available as a With symbol. Functions, structs, enums, constants — they're just there. No binding generators, no build scripts, no manual `extern "C"` blocks (though those exist too, when you want fine-grained control).

Calling an imported C function doesn't require `unsafe`. The `c_import` is your opt-in. You imported a C library; you know you're calling C code. Wrapping every call in `unsafe {}` is ceremony without safety. Raw pointer *dereferences* still need `unsafe` — that's where the real danger is.

## The Small Things

Language design lives in the details. Here are some that matter:

**Implicit Ok wrapping.** Functions returning `Result` don't need `Ok(value)` at the end. Just return the value. The `?` operator handles the sad path; the happy path just flows.

```
fn load_config(path: &str) -> Result[Config, AppError]:
    let text = fs.read_to_string(path)?
    let config = toml.parse(text)?
    config    // auto-wrapped in Ok(...)
```

**String literals just work.** `"hello"` auto-promotes to an owned `str` when the type expects it. No `.to_owned()` on every struct initialization.

```
let user = User { name: "Alice", email: "alice@example.com", role: .Member }
```

**Enum variant shorthand.** When the type is known, `.Variant` works without the full path.

```
fn default_role -> Role: .Member
```

**Pipeline operator.** Data flows left to right, naturally.

```
let report = transactions.iter()
    |> filter(|t| t.amount > 100.0)
    |> sorted_by(|a, b| b.date.cmp(a.date))
    |> take(10)
    |> map(|t| "{t.date}: ${t.amount}")
    |> join("\n")
```

**Comptime instead of macros.** No token-level metaprogramming. Compile-time execution of regular With code with access to type information. Generated code goes through the full type checker.

```
comptime fn derive_serialize[T: type] -> impl Serialize for T:
    let fields = T.fields()
    impl Serialize for T {
        fn serialize(self: &T, out: &mut JsonWriter):
            out.begin_object()
            for field in fields:
                out.key(field.name)
                self.{field.name}.serialize(out)
            out.end_object()
    }
```

None of these are revolutionary on their own. Together, they add up to a language that stays out of your way.

## Who It's For

With is for people who want Rust's safety guarantees without Rust's complexity tax. Concretely:

**Game developers** who want ECS patterns, dense data layouts, and native performance — without fighting the borrow checker every time they need two mutable references to different components.

**Backend engineers** who want compile-time safety and no GC pauses — without `Pin<Box<dyn Future<Output = Result<T, Box<dyn Error + Send + Sync>>> + Send>>` in their function signatures.

**Infrastructure developers** who want C interop, deterministic destruction, and zero-cost abstractions — without a six-month learning curve before they're productive.

**Anyone who tried Rust, liked the idea, and bounced off the execution.** You're not wrong. The idea is sound. The execution can be gentler.

## The Trade-offs

Every design decision has costs. Here are ours, stated plainly:

You cannot store references in structs. This means you can't write `struct Lexer { source: &str }`. You use `(source: &str, pos: usize)` as separate parameters, or store byte offsets, or use `with` blocks for scoped access.

You cannot return lazy iterators that borrow from their input (as opaque types). You `collect()` into owned containers, use generators, use callbacks, or process inline. There's a small allocation cost at function boundaries that Rust avoids.

Fibers use more memory than Rust's stackless futures — 8–64KB per fiber versus state-machine-sized for Rust. At 100K concurrent connections, that's real memory. For most servers, it's nothing.

Handle dereferences are slower than raw pointer access — about 2–3ns versus 0.3ns per lookup. For bulk operations, use iterators. For genuinely hot paths, `unsafe` is there.

These are real costs. For services, games, databases, and infrastructure — the domains With targets — they're the right trade.

## What's Next

With is in active development. The compiler bootstraps through Zig, the spec is at v6.5, and the standard library design covers I/O, networking, collections, concurrency, and FFI. The self-hosted compiler is operational — it compiles itself via a C backend, reaching a fixpoint at stage 3. Next up: a package manager (`with get`) and a VSCode extension backed by a language server.

If any of this resonates — if you've felt the gap between Rust's promise and Rust's daily experience — With might be worth watching.

The language is named after its central idea: working *with* your data, in a scope, with clear boundaries. Not fighting the compiler. Not annotating lifetimes. Not wrestling with type-level machinery to do something simple.

Just writing the code you meant to write.

---

*With is developed by QuixiAI. Follow along at github.com/QuixiAI/with.*