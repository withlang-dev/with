# With Compiler - Project Guidelines

## Ownership Mindset
We own this codebase. There is no such thing as a "pre-existing" bug. If we see a bug, we fix it — no hedging, no deferring, no labeling it as someone else's problem. Every bug in this repo is our bug.

## Reliability
Intermittent hangs and performance issues are P0. When encountered, investigate and solve them deeply — do not dismiss them as flakes, do not work around them, do not move on. Root-cause them.

## Build Integrity
The self-host build must never be broken. The pipeline is:
- Seed compiler → stage1 (compiles current source)
- Stage1 → stage2 (stage1 compiles current source)
- Stage2 → stage3 (stage2 compiles current source)

If the build breaks, fixing it is the top priority.

## Bootstrap
Bootstrap code (bootstrap/) is frozen except for critical bugs. The bootstrap compiler is a Zig implementation used only as a fallback seed. Source code in src/ must work around bootstrap limitations — src/ should contain no code that the bootstrap compiler cannot compile. Do not change bootstrap's architecture to accommodate src/.

## Language
Source files use `.w` extension. The language uses indentation-based syntax (like Python), with `fn`, `type`, `let`, `use`, `extern fn` as top-level declarations.

## Work Discipline
- **Fix bugs, don't work around them.** Don't disable a subsystem to avoid a bug in it. Don't add detection heuristics to route around broken code. Fix the broken code. Workarounds that try to enumerate failure cases are fragile and compound over time.
- **Do a 5 whys root-cause analysis.** When debugging a bug, trace it down with a 5 whys analysis until the deepest credible cause is clear, then fix that root cause instead of patching over the surface symptom.
- **Verify before writing code.** Don't guess at APIs, node layouts, or conventions from memory. Read the source definitions first (e.g., check Ast.w for node kinds before writing AST-walking code).
- **Bisect, don't spiral.** When a stage binary is broken, systematically bisect which source change caused it (revert half, rebuild, test) rather than chasing symptoms with a debugger. Corrupted stacks and pointers rarely yield useful debugger output.
- **Test incrementally.** Rebuild and smoke-test after each individual change. Batching multiple changes makes it hard to isolate which one broke things.
- **Seed corruption awareness.** In a self-hosting compiler, always ask: "is the seed compiler itself producing bad code?" before debugging the output binary. Bugs in the seed propagate through the stage chain. If the seed has a codegen bug, fix it in the bootstrap — that's exactly what "critical flaws" means.

## AST Node Layouts (common pitfalls)
- `NK_LET_DECL` (4): top-level let. d0=name(sym), d1=value(node), d2=flags (bit0=mut, bit1=pub)
- `NK_LET_BINDING` (33): let inside function bodies. d0=name(sym), d1=value(node), d2=flags (bit0=mut). There is NO `NK_VAR_DECL` — mutable bindings use LET_BINDING/LET_DECL with the mut flag.
- `NK_IF_EXPR` (31): d0=cond, d1=then, d2=else. NOT called `NK_IF`.
- `NK_FOR` (37): d0=binding(sym), d1=iterable(node), d2=body(node). Body is d2, NOT d1.
- `NK_WHILE` (35): d0=cond, d1=body, d2=label
- `NK_MATCH` (40): d0=subject, d1=extra_start, d2=arm_count
- `NK_MATCH_ARM` (110): d0=pattern, d1=body, d2=guard
- `NK_BLOCK` (30): d0=extra_start, d1=stmt_count, d2=tail(node)
- `NK_RETURN` (32): d0=value(node)
- `NK_STRUCT_LIT` (43): d0=name(sym), d1=extra_start, d2=field_count

## Debugging on macOS ARM64
When a stage binary crashes or hangs:
1. **Quick repro**: `time ./out/bin/with-stage2 check src/main.w`
2. **LLDB**: `lldb -- ./out/bin/with-stage2 check src/main.w` then `run` / `bt all`
3. **Heap corruption**: `MallocScribble=1 MallocGuardEdges=1 ./out/bin/with-stage2 check src/main.w`
4. **Leak check**: `leaks --atExit -- ./out/bin/with-stage2 check src/main.w`
5. **Instruments**: `xcrun xctrace record --template "Leaks" --output /tmp/trace.trace --launch -- ./out/bin/with-stage2 check src/main.w`
6. **Debug entitlement** (if "not debuggable"): `codesign -s - --entitlements /tmp/debug.entitlements --force ./out/bin/with-stage2`
- Prefer lldb, MallocScribble, leaks, xctrace. Avoid Valgrind on ARM64.

## Self-Host Bootstrapping
When the self-host build is broken and the seed compiler has codegen bugs, the stage chain can propagate corruption (bad seed → broken stage1 → broken stage2). To break the cycle:
- The bootstrap compiler (Zig) has no prelude support — it cannot compile current source that depends on Vec/HashMap from prelude.
- The rebuild script (`scripts/rebuild_selfhost.sh`) tries seed candidates in order: stage3, stage2, canonical, stage1, bootstrap.
- When `src/main` (the binary seed in the source tree) is updated, it can serve as a known-good seed to bootstrap from.
