# D130 — `--emit-c` emits what the program reaches; `--emit-all` emits everything (delegated)

**Laws:** 1 (docs/mission.md): the programmer never becomes the build system;
a translation unit carries what the program uses.

**Date:** 2026-10-14. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Context:** battery time (Eric's
#1 priority).

**Decision.** The C backend writes a function or global when the C it has
already written names it. The roots are the functions with external names
(exports, the public runtime ABI), `main`, closures, fn-value thunks and
global initializers that do more than compute their value; an initializer
that only computes its value (no call but a list literal's construction, no
drop running a user `Drop`, no write to a global) is reached through its
global. `--emit-all` (only with `--emit-c`) writes every function and global,
as before.

**Why.** Every program reaches all of pcre2 through the prelude's
`std.regex`, so `print("hi")` emitted 24 MB of C (6 MB of it pcre2's Unicode
tables as startup code) and took 12.7 s to emit and 8 s to compile;
emit-c-smoke, 34 programs, was a 200-240 s lane on the battery's critical
path. Now: 105 KB, 6 s, 0.02 s; the lane runs in 58 s. Nothing the program
reaches can go missing: a name the C uses is emitted, and a missing one would
fail the C compile loudly.

**What the others do.** Every native toolchain drops unreferenced code at
link time (`-dead_strip`, `--gc-sections`); With's own LLVM path does.
Clang's `-ffunction-sections` and Zig's lazy analysis emit only what is
referenced; Zig's C backend (`-ofmt=c`) emits only analyzed (reached)
declarations.

**What the spec says.** toolchain.md named `--emit-c` and nothing about its
content; the bootstrap runbook makes it the no-LLVM bootstrap's backend,
whose gate is `emit-c-fixpoint`. This adds one sentence and the flag.

**Mission fit.** No user-visible meaning changes; a C file a program does not
need is not written. `--emit-all` exists so the battery still proves the C
backend over all of std (emit-c-smoke's prelude case).

**Prediction.** Eric accepts (80%): build time is his first priority, the
flag is test surface, and nothing about C interop, ownership or safety moves.
What would reopen it: a consumer of emitted C that links it as a library and
calls functions the program itself never reaches.
