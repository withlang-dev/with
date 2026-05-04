# Prelude Design Guide (Self-Hosted Compiler)

## Scope

This plan is for the self-hosted compiler path only:

- `src/compiler/*`
- `src/main.w` (selfhost CLI flag plumbing)

Do not route this work through bootstrap-only orchestration paths for this task.

---

## Principle

The prelude is a normal With source file that the compiler implicitly
imports into every module. No hardcoded symbol list in the frontend.
If a name is in the prelude module graph, it is visible everywhere by
normal import resolution.

---

## Corrections To The Original Draft

The intent is correct, but a few details in the first draft were not
compatible with the current compiler/language state:

1. `pub use ...` is not currently supported in this parser/import model.
2. The example module paths (`std.vec`, `std.hashmap`, `std.parse`, etc.)
   do not match this tree's current stdlib layout.
3. `#[cfg(...)]` is not current attribute syntax in this codebase.
4. "Prelude is lowest priority" only holds if lookup remains
   "later declarations/imports override earlier ones"; the injected prelude
   must therefore be loaded before explicit imports.

This document fixes those issues while keeping the same architectural
direction.

Additional policy guard (to avoid confusing shadowing):

5. The implicit prelude import must resolve to stdlib-owned prelude files
   only; project-local files must not shadow it.

---

## File: `lib/std/prelude.w`

Use a plain module with plain `use` declarations (no re-export syntax
dependency).

```with
// lib/std/prelude.w
// Keep this list to modules/names that do not create unresolved collisions
// in the current import model.

use std.math
use std.string
use std.iter
use std.fs
use std.process
```

Notes:

- In the current import-expansion model, this is enough to make those
  modules ambient when the prelude is injected.
- Avoid importing modules that introduce conflicting free-function names
  until selective re-export/import support exists.
  Example: `std.option` and `std.result` both define names like `map`/`filter`
  that can collide with `std.iter`.

### Core prelude file

```with
// lib/std/prelude_core.w
use std.string
use std.math
```

---

## Compiler Change: One Implicit Import

### Where to implement (selfhost path)

Inject the implicit prelude in the selfhost frontend import pipeline:

- `src/compiler/Frontend.w`
- via `Zcu.compile_source_frontend(...)` / import expansion helpers

Do not implement this in bootstrap `Driver` flow for this task.

### Mechanism

Before processing user `use` imports, inject one synthetic `use` decl:

```with
if prelude_mode == PRELUDE_FULL:
    inject_use_decl("std.prelude")
if prelude_mode == PRELUDE_CORE:
    inject_use_decl("std.prelude_core")
if prelude_mode == PRELUDE_NONE:
    // inject nothing
```

`inject_use_decl` should produce the same AST shape as parser-produced
`use` declarations so normal import resolution/expansion handles it.

For this implicit path only, resolve directly to:

- `lib/std/prelude.w`
- `lib/std/prelude_core.w`

Do not route implicit prelude resolution through normal source-dir-first
module search order; that prevents local `std/prelude.w` (or similarly
named files) from accidentally shadowing the standard prelude.

---

## Resolution Priority

Target lookup precedence:

1. Local bindings (let/var/params)
2. Current module definitions
3. Explicit `use` imports
4. Prelude imports

With the current "later declarations/imports override earlier ones"
behavior, this is achieved by injecting prelude imports first.

If resolution semantics change later, preserve this precedence explicitly
and keep prelude lowest priority.

### Ambiguity behavior

Prelude collisions should not introduce new hard errors: explicit/local
definitions should continue to win. Keep existing explicit-import conflict
behavior unchanged.

---

## Build Modes

### Normal (default)

```bash
with build program.w
```

Implicitly imports `std.prelude`.

### `--no-prelude`

```bash
with build --no-prelude program.w
```

No implicit prelude import.

### `--prelude=core`

```bash
with build --prelude=core program.w
```

Implicitly imports `std.prelude_core`.

### `--freestanding`

```bash
with build --freestanding program.w
```

Equivalent policy target:

- no implicit prelude
- no std runtime linkage

In this tree, thread this consistently with existing `--no-std`.

---

## Selfhost Implementation Checklist

### 1. Prelude source files

- [x] Add `lib/std/prelude.w` (full)
- [x] Add `lib/std/prelude_core.w` (minimal)
- [x] Ensure both parse and import correctly as normal modules

### 2. Frontend implicit-use injection

- [x] Add helper in `src/compiler/Frontend.w` to synthesize a `use` decl
      from module path segments.
- [x] Inject the selected prelude use before explicit user imports are
      expanded.
- [x] Ensure injected prelude import has lowest effective precedence.
- [x] Ensure implicit prelude path is stdlib-pinned and cannot be shadowed
      by project-local files.

### 3. CLI/config plumbing (selfhost path)

- [x] Parse `--no-prelude`
- [x] Parse `--prelude=core|full`
- [x] Parse/alias `--freestanding` to "no prelude + no std/runtime policy"
- [x] Thread through:
      `src/main.w` -> `src/compiler/Compilation/Config.w`
      -> `src/compiler/Compilation.w` -> frontend/ZCU state

### 4. Hardcoded symbol cleanup (phased)

Phase A (now):

- [x] Do not add new hardcoded std names for prelude symbols.
- [x] Keep existing shared-stage builtins that current selfhost still
      depends on.

Phase B (for prelude-provided std names in the current selfhost path):

- [x] Remove hardcoded builtin symbol handling for prelude-provided std
      symbols and source them from std/prelude modules.

### 5. Tests

- [x] Hello world compiles with no explicit imports in default mode.
- [x] Prelude functions from imported modules resolve without explicit use.
- [x] Local `fn map` shadows prelude-provided `map`.
- [x] Explicit `use other.map` shadows prelude-provided `map`.
- [x] `--no-prelude` removes ambient prelude names.
- [x] `--prelude=core` exposes only core set.
- [x] `--freestanding` disables ambient std symbols.
- [x] Existing explicit-import conflict behavior remains unchanged.

---

## What Stays Hardcoded (Current Practical Boundary)

Keep hardcoded only what cannot yet be represented as normal library
imports in the current selfhost architecture:

- compiler directives (`c_import`, comptime machinery)
- primitive type/literal semantics (`i*`, `u*`, `f*`, `bool`, `str`,
  `true`, `false`)
- operator desugaring hooks
- any currently unavoidable shared-stage builtin hooks that are not part
  of the prelude-owned std surface (for example current collection/runtime
  intrinsics and diverging builtins)

Long-term target remains: everything user-facing (`println`, `assert`,
`map`, `sum`, etc.) comes from std modules via prelude imports.

---

## Long-Term Follow-up (When Language Support Expands)

When selective re-export/import support exists (`pub use`-style and
symbol-level conflict controls), upgrade `prelude.w` from module-level
`use` to granular exports. That enables cleaner inclusion of modules like
`std.option`/`std.result` without free-function name collisions.
