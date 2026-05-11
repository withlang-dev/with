# The With Programming Language: A Timeline

Generated from the project’s git history and edited to make the commit graph readable by humans. This timeline summarizes the major implementation milestones, releases, rewrites, and architectural changes in With’s first three months.

## 2026

### February

**Feb 12-18 — Original specification drafted**
The first week is spent designing the language on paper: syntax, ownership and borrowing, structs, enums, traits, generics, closures, pattern matching, async/await, comptime execution, C interop, package management, and the compiler architecture. By the end of the week, With has a coherent shape before implementation begins.

**Feb 19 — First commit**
The language specification, example programs, and compiler implementation plan land in the repository. With moves from design document to codebase.

**Feb 24-25 — The 48-hour compiler**
In an extraordinary burst of development, the first working compiler is built in Zig. By the end of Feb 25, the language has structs, enums, traits, generics, closures, pattern matching, dynamic dispatch, async/await, generators, channels, comptime expressions, an interactive REPL, a documentation generator, an LSP server, and **400 passing tests**. The language’s shape is established in two days of implementation.

**Feb 26 — Zig compiler complete**
The Zig-based bootstrap compiler is finished and the codebase migrates to v6.4 syntax.

**Feb 27 — Self-hosting begins**
The With compiler compiles itself for the first time, emitting C as an intermediate backend. The language is now written in itself.

---

### March

**Mar 2-4 — Wave-based self-hosting**
Twelve waves of systematic self-hosting work replace the Zig compiler internals with native With code: lexer, parser, resolver, semantic analysis, and codegen are all rewritten.

**Mar 9 — Fixpoint achieved**
The compiler becomes fully self-sustaining: `stage2 == stage3` byte-for-byte. The Zig bootstrap is dead. On the same day, LLVM is statically linked into the binary, producing a self-contained 49MB compiler with no external dependencies.

**Mar 11 — Borrow checker and debug info**
DWARF debug info lands. The borrow checker gains multi-level field path disjointness analysis and closure capture tracking.

**Mar 12-13 — Generic type instantiation**
`TY_GENERIC_INST` brings true monomorphized generics: `Vec[i32]` and `Vec[str]` become distinct types with distinct codegen.

**Mar 13-15 — MIR pipeline**
A new Mid-level Intermediate Representation replaces direct AST-to-LLVM codegen. Coverage climbs from 0% to 99.8% in three days.

**Mar 16 — AST codegen deleted**
The old AST codegen path is removed entirely. Every function now compiles through MIR. The compiler’s internal architecture reaches its modern form.

**Mar 16-19 — C interop reaches Zig parity**
`c_import` gains full AST traversal, struct/typedef translation, macro expansion, function body translation, and passes all 53 tests across 15 system headers. A side-by-side comparison confirms parity with Zig’s `translate-c`.

**Mar 20 — Spec-driven feature sprint**
Copy trait, distinct types, named arguments, for-else loops, `sizeof`/`alignof`/`transmute` intrinsics, and async codegen all land in a single day, driven by the language specification checklist.

**Mar 22 — Package management**
`with init` and `with get` bring dependency resolution and project scaffolding.

**Mar 23 — Native HTTPS for package management**
BearSSL is ported to With, giving `with get` a native TLS 1.2 stack without depending on system `curl`. The port covers SHA-256, HMAC, AES-GCM, RSA, ECDSA P-256, X.509 parsing, and an HTTP client — scoped to package registry communication and built on a proven C implementation.

**Mar 23 — F-string formatting**
A 67-task plan delivers Python-style f-strings with format specs for width, padding, hex, and precision; debug mode with `:?`; and struct formatting. The compiler’s own diagnostics migrate from string concatenation to f-strings.

**Mar 24 — The great enumification**
Every major constant group in the compiler — `NK_*`, `TK_*`, `TY_*`, and dozens more — converts from raw integers to discriminant enums. The compiler eats its own type system.

**Mar 27 — Type-safe IDs and compiler refactor**
`NodeId` and `TypeId` become distinct types instead of raw `i32`s. `Codegen.w` splits from 10,559 to 3,993 lines. `Sema.w` splits from 9,112 to 1,847 lines. `with fmt` and `with test --filter` ship.

**Mar 28-29 — Comptime evaluation**
A dedicated compile-time evaluator replaces ad-hoc constant folding, enabling dead branch pruning, derive lowering, collection freezing, and comptime intrinsics.

**Mar 30 — Language Server Protocol**
Seven phases of LSP development land in a single day: cached analysis, scope-aware completion, error-tolerant parsing, cross-file go-to-definition, signature help, type-aware dot completion, and find-all-references.

**Mar 31 — Libc eliminated**
Pure With programs no longer link against libc. A native runtime provides syscall wrappers, memory allocation, and process control directly. With begins acting like a standalone systems language, not a compiler frontend riding on C infrastructure.

---

### April

**Apr 2 — Async/await with fibers**
Stackful fibers, `Task[T]`, `spawn`, `select await`, channels with backpressure, guard pages, cancellation with defer unwinding, and tuple await all ship. Structured concurrency becomes a first-class language feature.

**Apr 5 — Zero C source files**
`helpers.c`, `with_runtime.c`, `llvm_bridge.c`, and `clang_bridge.c` are all rewritten in With. The compiler contains zero lines of C.

**Apr 6 — C-to-With migration tool**
`with migrate` translates C source files to idiomatic With, including goto elimination through control-flow-graph analysis, macro expansion, type translation, and libc call mapping.

**Apr 8-14 — PCRE2 migration**
The PCRE2 regex library, 73K lines of C, is migrated to With using `with migrate`. Dozens of migrator bugs are found and fixed in the process. The migration produces 31 error-free With modules totaling roughly 160K lines.

**Apr 14 — Release v0.13.0**
The first major public checkpoint after self-hosting, MIR, native runtime work, C migration tooling, and the PCRE2 migration push.

**Apr 17 — Three block forms**
The parser accepts colon blocks, brace blocks, and inline expressions at every block-introducer site. `with fmt` gains `--prefer-brace` and `--prefer-colon` flags.

**Apr 25 — Labeled control flow and native goto**
Labeled `break` and `continue` arrive with apostrophe syntax, such as `'outer`. First-class `goto` supports systems programming and C migration. CFG-based stackify lowering replaces state-machine transformation.

**Apr 25 — Release v0.13.1**
A second release checkpoint lands after the block-form work, control-flow additions, and migration improvements.

**Apr 27-28 — Mutability model**
The ownership and borrowing system is redesigned. `mut self` receivers replace the earlier `&mut` model. Place classification, NLL-style view liveness analysis, closure capture conflict detection, and 13 new diagnostic categories ship, covering the full §15 of the spec. `&mut T` is rejected from safe With code. This is a deliberate break from Rust’s model: With chooses persistent ownership, ephemeral borrowing, and handles for relationships.

---

### May

**May 1 — NLL borrow checking**
Non-lexical lifetime analysis lands with scoped borrow expiry. Three-location diagnostics pinpoint exactly where a borrow originates, where it is used, and where the conflict occurs.

**May 2 — Scoped access APIs**
`VecSlot`, `Vec.get_disjoint`, `Vec.range`, `Vec.iter_ref`, and `HashMapEntry` provide safe scoped mutation without exposing raw references.

**May 4 — Calling convention model**
Explicit `copy` and `move` annotations at call sites, `&Self` and `move self` receiver modes, effect summary inference, escape analysis, and closure capture conventions land together.

**May 6 — Implicit main and open source**
Scripts can omit `fn main`: top-level statements run directly. The project is released under the MIT License.

**May 8 — Regex integration and CLI one-liners**
Regex literals, such as `/pattern/flags`, become first-class syntax with `=~` and `!~` operators plus `$1` and `$name` capture bindings. PCRE2 passes the upstream 8-bit test corpus. `with -e`, `with -n`, and `with -p` enable Perl-style one-liners.

**May 8-10 — PCRE2 migrator hardening**
Seven compiler and migrator bugs are found and fixed through PCRE2 test suite failures: integer sign-extension in codegen, comma-expression side-effect loss, C integer promotion for small types, `sizeof` for pointer types, function address-of lowering, `sizeof` with macro type aliases, and AST session lifetime during macro translation.

**May 9-10 — Build system**
`build.w` replaces Makefile-driven builds with declarative target graphs, include path propagation, and generated source support.

**May 10 — Do-while loops**
`do: body while condition` is added to the language. `continue` jumps to the condition check, matching C semantics. The construct reduces `goto` usage in migrated code by providing a structured form for the do-while pattern.

**May 11-12 — Derive macros and JSON**
`@[derive(Default)]`, `@[derive(SoA)]`, `@[derive(Serialize)]`, and `@[derive(Deserialize)]` generate trait implementations at compile time, including support for generic structs with trait bounds. `std.json` gains a `JsonWriter`, `JsonDocument` parser, and `Serialize`/`Deserialize` traits with primitive implementations.

**May 12 — Forward type resolution fix**
Sema’s deferred type resolution is corrected to re-resolve composite types — pointers, arrays, tuples, and function types — whose leaf types are still incomplete. This fixes MIR field-access failures for forward-declared struct pointers and unblocks the `Deserialize` derive for generic structs.
