# With Language — Implementation Roadmap

**Companion to:** `docs/with-specification.md`

---

## Phased Implementation

### Phase 0: Bootstrap + C Interop

Lexer, parser, AST. Module system (with prelude imports). Basic types
including record update syntax and ranges. Type checker (local
inference, explicit signatures). Backend: C codegen or Cranelift.

**`c_import` and FFI are Phase 0.** `extern "C"` declarations,
`@[repr(C)]`, `unsafe` blocks, raw pointer types, and `c_import`
header parsing are implemented in the bootstrap phase. Without C
interop, the language cannot call libc, cannot open files, cannot
allocate memory, cannot write tests against real libraries. Every
subsequent phase depends on this.

**Milestone:** Can `c_import("stdio.h")` and call `printf` from With.

### Phase 1: Ownership Core

Move semantics. Copy. Borrow checker (NLL, disjoint fields). Ephemeral
type qualifier. Reference return with propagation.

**Milestone:** Spec tests for SS2–SS5 pass (`test/spec/spec_ss02_*.w`
through `test/spec/spec_ss05_*.w`).

### Phase 2: Ergonomic Surface

`with` blocks. Closures with escaping detection. Partial application.
Pipelines and function composition (`>>`, `<<`). `in` / `not in`
operator with `Contains` trait and literal optimizations. Pattern
matching (full: nested, or-patterns, `@` binding, `if let`, `in`
patterns, slice, parameter patterns). Error types. Tail call
optimization.

**Milestone:** Spec tests for SS7, SS9, SS10 pass.

### Phase 3: Standard Library

Implement the standard library module map defined in §18.6:

**Phase 3a (Core):** `std.io` (Reader, Writer, print/eprint/write),
`std.fs` (File, read_file, write_file), `std.mem` (size_of,
align_of, copy), `std.fmt` (Display, Debug, format),
`std.collections` (Vec, HashMap, HashSet, SlotMap, Handle),
`std.string` (String, StrView methods). Option and Result with
full combinator APIs including sequence/traverse/transpose.

**Phase 3b (Systems):** `std.time` (Instant, Duration, SystemTime),
`std.math` (f32/f64 methods, constants), `std.process` (args, env,
exit), `std.random` (Rng), `std.hash` (Hasher, DefaultHasher).

**Phase 3c (Concurrency foundations):** `std.thread` (spawn_os,
JoinHandle), `std.sync` (Mutex, RwLock, Atomic, Condvar).
Generator lowering.

All modules use `c_import` internally for platform bindings (libc,
POSIX, Win32). Users never see `c_import` for standard operations.

**Milestone:** Spec tests for SS6, SS13, SS15, SS18 pass.
Users can write file I/O, string processing, timing, and
collections code without any `c_import`.

### Phase 4: Concurrency

Fiber runtime (§14.18–14.19). `async`/`await` lowering. Task type.
Structured concurrency. Channels. Select. `no_runtime` gate.
Send/Sync trait enforcement. `std.net` (TcpListener, TcpStream,
UdpSocket, DNS). `std.signal`.

**Milestone:** Spec tests for SS14 pass. A simple HTTP server runs
with concurrent connection handling.

### Phase 5: Traits and Generics

Definitions, implementations, orphan rules, generic bounds,
monomorphization.

**Milestone:** Spec tests for SS11 pass.

### Phase 6: Polish

Comptime. Formatter. Doc generator. LSP. REPL. Diagnostics.
Optimization. `c_import` macro translation improvements.

---

## Known Limitations and Trade-Offs (v1.0)

| Limitation | Cost | Workaround |
|------------|------|------------|
| Cannot store references in structs | Forces `(&Tree, NodeId)` pairs instead of `&Node` | Use handles, owned values, or `with` blocks |
| Cannot return iterators that borrow | May require allocation at function boundaries | Use `collect`, generators, callbacks, or inline pipelines (§13.1) |
| Cannot build self-referential structs | Must restructure as separate arena + handle | Use arenas with handles |
| Handle dereference slower than pointer | ~2-3ns vs ~0.3ns per access | Use `for_each`/`iter` for bulk; `unsafe` for rare hot paths (§6.3) |
| Fibers use 8–64KB stack each | 100K fibers ≈ 800MB worst case (vs state-machine-sized for Rust futures) | Growable stacks; channel-driven worker pools for >100K tasks (§14.19) |
| No RAII wrappers around borrowed resources | Cannot `Drop` a struct holding `&mut File` | Use `defer` or `with` blocks |
| No higher-kinded types | Cannot abstract over `Option`/`Result`/etc. generically | Use concrete generic parameters |
| No associated types on traits | Verbose generic signatures | Use additional generic parameters |
| Array index disjointness not proven | Conservative rejection of safe code | Use `get2_mut` or `split_at_mut` |
| Closure escaping analysis conservative | Some valid closures rejected | Pass closure directly as argument |
| Fiber runtime required for async | `async` unavailable on bare-metal | OS threads always available; `no_runtime` for embedded |
| Bare string literal allocation not guaranteed away | Performance-sensitive code cannot rely on optimizer proof | Use explicit `&str` annotation for guaranteed zero-cost static reference |

---

## Future Work

- Associated types on traits
- Hot-reload for debug builds
- Relaxed orphan rules
- Relaxed closure escaping analysis
- Inferred borrow provenance (compiler infers which parameter a
  return value borrows from, eliminating conservative multi-borrow)
- Fiber scheduler work-stealing optimizations
- Distributed async
- Nested record update syntax (`{ e with transform.pos.x: ... }`)
- Persistent immutable collections (`ImmMap`, `ImmVec`) as explicit types
- Extractor patterns (constrained Scala-style `unapply`, if provably
  safe for exhaustiveness checking)
- Unified ECS query combinator: `world.query[A, B]()` as a single
  entry point for compile-time-optimized multi-component queries,
  replacing per-arity functions like `query2`, `query3`
