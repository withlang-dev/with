# AGENTS.md — With Compiler

This document defines **rules for AI agents working in this repository**.

The With compiler is **self-hosting**. Small mistakes can corrupt the stage chain, so strict discipline is required.

---

# Core Principles

## Ownership

We own this entire codebase.

There is no such thing as a "pre-existing bug".
If a bug exists, **we fix it**.

Never defer or work around bugs.

---

## Reliability

Intermittent hangs and performance regressions are **P0**.

Never:

* dismiss as flakes
* add workarounds
* add detection heuristics
* disable functionality

Always **root-cause the issue**.

---

# Build System

The compiler compiles itself.

Build:

```
make build
```

Stages:

```
seed → stage1 → stage2
```

Verify determinism:

```
make fixpoint
```

This verifies:

```
stage2 == stage3
```

(byte-identical)

If the build breaks, **fixing the build is the top priority**.

---

# Seed Compiler

The seed compiler is resolved in this order:

1. `WITH=<path>`
2. `with` on PATH
3. `src/main`

`src/main` is a **fixpoint-verified stage2 binary** committed to the repo.

After a successful fixpoint build, update the seed.

Catastrophic loss scenario:

If these are all broken:

* `src/main`
* installed compiler
* external selfhost binaries

then **the compiler cannot be recovered**.

---

# Repository Layout

All build artifacts must live under `out/`.

```
runtime/      C runtime source (.c .h .s)

out/bin/      compiler binaries
out/lib/      compiled runtime (.o), LLVM link config
out/log/      build logs
```

Source directories must **never contain build artifacts**.

---

# LLVM Linking

LLVM is **statically linked** into the compiler binary. No dynamic `libwith_llvm_bridge.dylib` dependency.

Build-time setup (`scripts/ensure_runtime.sh`):

1. Compiles `runtime/llvm_bridge.c` → `out/lib/llvm_bridge.o` using LLVM's clang
2. Generates `out/lib/llvm_link.rsp` with LLVM static lib paths + system deps
3. Writes `out/lib/llvm_cc` with path to LLVM's clang

At link time (`src/compiler/Link.w`):

* Detects `llvm_bridge.o` + `llvm_link.rsp` + `llvm_cc` → static linking via LLVM's clang with `-fuse-ld=lld`
* Falls back to `libwith_llvm_bridge.dylib` if static bridge not available

LLVM location: `/usr/local/llvm` (override with `LLVM_PREFIX` env var).

Apple's system linker cannot parse LLVM 22 bitcode — the compiler **must** use LLVM's own `ld.lld`.

---

# Language Overview

Source files use `.w`.

The language is indentation-based (similar to Python).

Top-level declarations:

```
fn
type
let
use
extern fn
```

---

# Agent Editing Protocol

When modifying compiler code, follow this exact workflow.

---

## 1. Read Before Editing

Before writing code:

* read relevant source files
* confirm AST layouts
* verify naming conventions

Never rely on memory.

---

## 2. Make One Logical Change

Avoid batching unrelated changes.

Small commits make debugging possible.

---

## 3. Rebuild Immediately

After each change:

```
make build
```

Smoke test:

```
./out/bin/with-stage2 check src/main.w
```

---

## 4. If the Compiler Breaks

Stop adding new changes.

Begin **bisect debugging**.

---

# Stage Debugging Playbook

When a stage binary crashes or hangs:

### Quick repro

```
time ./out/bin/with-stage2 check src/main.w
```

### LLDB

```
lldb -- ./out/bin/with-stage2 check src/main.w
run
bt all
```

### Heap corruption

```
MallocScribble=1 MallocGuardEdges=1 \
./out/bin/with-stage2 check src/main.w
```

### Leak detection

```
leaks --atExit -- ./out/bin/with-stage2 check src/main.w
```

### Instruments

```
xcrun xctrace record \
  --template "Leaks" \
  --output /tmp/trace.trace \
  --launch \
  -- ./out/bin/with-stage2 check src/main.w
```

Preferred tools:

* lldb
* MallocScribble
* leaks
* xctrace

Avoid **Valgrind on ARM64**.

---

# Root Cause Discipline

When debugging a bug:

Perform a **5 Whys analysis**.

Trace the failure chain until the deepest credible cause.

Fix the root cause — **never the symptom**.

---

# Seed Corruption Awareness

In self-hosting compilers, the seed compiler may produce incorrect machine code.

Symptoms include:

* crashes in unrelated code
* impossible pointer values
* corrupted stacks
* deterministic failures after small changes

If suspected:

Replace the seed compiler with a known-good binary.

---

# Compiler Invariants

These rules must **always remain true**.

If any invariant is violated, it is a compiler bug.

---

## AST Node Validity

Every AST node must have a valid `kind`.

Invalid kinds indicate:

* parser bugs
* memory corruption
* incorrect node allocation

---

## Node Field Semantics

Node field meanings must never change without updating all consumers.

Example:

```
NK_IF_EXPR
d0 = condition
d1 = then
d2 = else
```

---

## Symbol References

Symbol nodes must reference a valid symbol table entry.

Invalid references indicate scope resolution bugs.

---

## Block Structure

```
NK_BLOCK
d0 = extra_start
d1 = stmt_count
d2 = tail expression
```

Rules:

* statement count must match stored statements
* tail must be valid node or null

---

## Match Arm Counts

```
NK_MATCH
d2 = arm_count
```

Stored arms must equal `arm_count`.

---

# Semantic Invariants

### Variable Mutability

Mutable variables use the **mut flag**.

There is **no `var` declaration**.

---

### Expression Validity

Expressions must never produce:

```
null
invalid node
uninitialized node
```

---

### Control Flow

Nodes like `if`, `match`, and `block` must produce a value in expression context.

---

# Stage Chain Invariants

The stage chain must follow:

```
seed → stage1 → stage2 → stage3
```

Invariant:

```
stage2 == stage3
```

If fixpoint fails, code generation is nondeterministic.

---

# AST Node Layouts (Common Pitfalls)

```
NK_LET_DECL (4)
d0 = name(sym)
d1 = value(node)
d2 = flags
  bit0 = mut
  bit1 = pub
```

```
NK_LET_BINDING (33)
d0 = name(sym)
d1 = value(node)
d2 = flags
  bit0 = mut
```

Important:

There is **NO `NK_VAR_DECL`**.

---

```
NK_IF_EXPR (31)
d0 = cond
d1 = then
d2 = else
```

---

```
NK_FOR (37)
d0 = binding(sym)
d1 = iterable(node)
d2 = body(node)
```

Body is **d2**, not d1.

---

```
NK_WHILE (35)
d0 = cond
d1 = body
d2 = label
```

---

```
NK_MATCH (40)
d0 = subject
d1 = extra_start
d2 = arm_count
```

---

```
NK_MATCH_ARM (110)
d0 = pattern
d1 = body
d2 = guard
```

---

```
NK_BLOCK (30)
d0 = extra_start
d1 = stmt_count
d2 = tail
```

---

```
NK_RETURN (32)
d0 = value
```

---

```
NK_STRUCT_LIT (43)
d0 = name(sym)
d1 = extra_start
d2 = field_count
```

---

# Where Compiler Bugs Usually Hide

When debugging, check these areas first.

1. AST construction
2. symbol resolution
3. block statement accounting
4. control flow construction
5. match lowering
6. iteration nodes
7. codegen ordering
8. seed corruption

Most compiler bugs occur in the first three.

---

# Code Generation Determinism

The compiler must produce deterministic output.

Avoid:

* iterating unordered maps
* pointer-address ordering
* nondeterministic traversal

These break fixpoint verification.

---

# Dangerous Mistakes

Avoid these common errors.

### Misreading AST layouts

Always confirm field meanings.

---

### Introducing build artifacts into source directories

All artifacts must go under `out/`.

---

### Guessing APIs

Read the source first.

---

### Working around compiler bugs

Always fix the root cause.

---

### Debugging corrupted stage binaries

If stacks are nonsense, suspect seed corruption.

---

# Agent Success Checklist

A change is acceptable only if all of these succeed:

```
make build
```

```
make fixpoint
```

```
./out/bin/with-stage2 check src/main.w
```

If any step fails, continue debugging until it passes.
