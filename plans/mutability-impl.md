# Implementation Plan: docs/mutability.md

## Context

`docs/mutability.md` is a 786-line comprehensive specification for the With language's mutability and calling-convention model. The doc defines six axes: binding stability, value mutation, calling convention, receiver modes, effect summaries, and effect pinning.

**Goal**: Implement all features described in the doc.

**Already implemented (skip):**
- `var` keyword / `let` for binding stability (Parser.w:801, 5107)
- `mut self: Self` receiver mode with call-site enforcement (Ast.w:214, SemaCheck.w:8255)
- Basic borrow checker with SHARED/EXCLUSIVE live borrows (Sema.w:341–350)
- `&T` reference type (TY_REF = 14)

**Not yet implemented (this plan):**
- `copy`/`move` call-site argument annotations (`f(copy x)`, `f(move x)`)
- Copy trait tracking for aggregates
- `&Self` and `move self: Self` receiver modes (only `mut self` is complete)
- Effect summary inference (read/write/consume/escape_value/escape_view)
- Effect pinning via `@[effect(...)]` attribute
- View-origin tracking for `escape_view`

---

## Phase 1: Call-Site Passing Modes (`copy x`, `move x`)

**The most impactful missing feature.** Without these, the calling convention model can't be demonstrated.

### 1a. Token and AST Nodes

**src/Token.w**: Add `TK_KW_COPY` token near `TK_KW_MOVE` (line ~132). The keyword `copy` is not yet in the lexer.

**src/Ast.w**: Add two new node kinds:
- `NK_COPY_ARG` — wraps an expression to indicate copy-passing at call site
- `NK_MOVE_ARG` — wraps an expression to indicate move-passing at call site (distinct from `move ||` closures)

Both nodes: `d0 = inner_expr_node`, d1/d2 unused.

### 1b. Parsing

**src/Parser.w**: In `parse_call` (around line 3274), in the argument loop before calling `parse_expr()`, check:
```
if self.peek() == TK_KW_COPY:
    self.advance()
    let inner = self.parse_expr()
    arg = self.node_with(NK_COPY_ARG, inner, 0, 0)
else if self.peek() == TK_KW_MOVE:
    // check next token isn't `||` (that's a closure)
    if self.peek_ahead(1) != TK_PIPE and self.peek_ahead(1) != TK_PIPE_PIPE:
        self.advance()
        let inner = self.parse_expr()
        arg = self.node_with(NK_MOVE_ARG, inner, 0, 0)
    else:
        arg = self.parse_expr()  // move closure
else:
    arg = self.parse_expr()
```

### 1c. Semantic Checking

**src/SemaCheck.w**: In call argument checking:

For `NK_MOVE_ARG`:
- Type-check inner expr normally
- Record the symbol as "moved" in the borrow checker (invalidate binding)
- Error if the symbol is already moved or is a with-binding

For `NK_COPY_ARG`:
- Type-check inner expr normally
- Check type implements `Copy` or `Clone`; error otherwise
- If `Clone` only, generate a `.clone()` call in MIR lowering

### 1d. MIR / Codegen

**src/MIR.w** and **src/Codegen.w**:
- `NK_MOVE_ARG`: lower as the inner expression (same as a value move — the key difference is binding invalidation in sema, codegen is same as passing the value)
- `NK_COPY_ARG` on `Copy` types: lower as inner expression (copy happens automatically)
- `NK_COPY_ARG` on `Clone`-only types: lower as `inner.clone()` method call

### Tests
- `test/behavior/behav_mut_md_copy_move.w`: test `f(copy x)` and `f(move x)` basic cases
- `test/compile_errors/err_copy_non_copy.w`: error when `copy x` on non-Copy/non-Clone type
- `test/compile_errors/err_move_invalidates.w`: error when using moved binding

---

## Phase 2: Copy Trait Tracking for Aggregates

The doc says: primitives are `Copy` by default; aggregate types are non-Copy by default, opt-in via `impl Copy for T` or `: Copy`.

### 2a. Determine Current State

First, grep for `is_copy`, `trait_copy`, `impl Copy` in src/Sema.w and src/SemaCheck.w to see what's already tracked. (The trait system has blanket impl support; `Copy` may already exist.)

### 2b. If Not Tracked: Add Copy Flag to Type Descriptors

**src/Sema.w**: Add a `is_copy` flag to struct/enum type descriptors. Primitives (i32, u8, bool, f64, char, etc.) are marked copy at type-system initialization. Structs/enums default to non-copy unless `impl Copy for T` is present.

### 2c. `type T: Copy { ... }` Syntax

Parser.w may already parse the `: TraitName` after type declaration name. Verify it creates an impl for Copy and sets the is_copy flag.

### 2d. Call-Site Copy-ness Rules

**src/SemaCheck.w**: At call argument checking:
- For default `f(x)` where arg type is Copy: no action needed (codegen copies)
- For default `f(x)` where arg type is non-Copy: track as share-place alias (ephemeral borrow)
- This distinction matters for effect checking in Phase 4

### Tests
- `test/behavior/behav_copy_aggregate.w`: Copy struct passed by value; mutation in callee doesn't affect caller
- `test/behavior/behav_non_copy_shared.w`: Non-Copy struct share-place; mutation in callee visible in caller

---

## Phase 3: Complete Receiver Modes (`&Self`, `move self: Self`)

Only `mut self: Self` is fully implemented. `&Self` and `move self: Self` need explicit flag tracking and enforcement.

### 3a. Flags

**src/Ast.w** (around line 214 near `FN_PARAM_FLAG_MUT_SELF`): Add:
- `FN_PARAM_FLAG_REF_SELF` — receiver is `&Self` (read-only view)
- `FN_PARAM_FLAG_MOVE_SELF` — receiver is `move self: Self` (consuming)

### 3b. Parsing

**src/Parser.w**: In method parameter parsing (around line 5997 where `FN_PARAM_FLAG_MUT_SELF` is set), also detect:
- `self: &Self` → set `FN_PARAM_FLAG_REF_SELF`
- `move self: Self` → set `FN_PARAM_FLAG_MOVE_SELF`

The `&Self` case currently parses `&Self` as a type annotation. Change to also set the flag.

### 3c. Semantic Enforcement

**src/SemaCheck.w**:

For `&Self` methods:
- At method body: flag that self is a read-only reference. Any mutation of self (field assignment, calling a `mut self` method on self) is a compile error.
- At call site: treated as a read borrow of the receiver (no mutation).

For `move self` methods:
- At call site: receiver binding is invalidated (same as `move x` for free functions).
- The receiver cannot be used after the call.
- Error: calling a `move self` method on a with-binding (with-bindings are not rebindable).

**Plain `fn method(self: Self)` with no mode annotation**: Per the doc, this is a compile error. Enforce this: if a method's self parameter has no receiver mode flag, emit error "method receiver must be &Self, mut Self, or move Self".

### Tests
- `test/compile_errors/err_no_receiver_mode.w`: method without receiver mode annotation → error
- `test/compile_errors/err_ref_self_mutation.w`: mutation of `&Self` receiver → error
- `test/behavior/behav_move_self.w`: `move self` method invalidates receiver at call site

---

## Phase 4: Effect Summary Inference (Core Borrow-Checker Model)

This is the largest phase. The doc's full borrow-checking model depends on per-parameter effect sets.

**Effects**: `read`, `write`, `consume`, `escape_value`, `escape_view`

### 4a. Data Structures

**src/Sema.w**: Add per-function effect tracking during body analysis:
```
fn_param_effects: Vec[i32]      // bit set per param: EFF_READ|EFF_WRITE|EFF_CONSUME|EFF_ESCAPE_VALUE|EFF_ESCAPE_VIEW
fn_param_origins: Vec[i32]      // for escape_view: which params are view origins (bitmask over param indices)
```

Define effect constants (as named module-level lets or a small enum):
```
EFF_READ         = 0x01
EFF_WRITE        = 0x02   // implies read
EFF_CONSUME      = 0x04
EFF_ESCAPE_VALUE = 0x08
EFF_ESCAPE_VIEW  = 0x10
```

### 4b. Effect Inference During Type-Checking

**src/SemaCheck.w**: As each operation on a parameter is analyzed, update the effect set:

| Operation | Effect contributed |
|---|---|
| Reading param value | `read` |
| Field assignment `param.field = ...` | `write` |
| Calling `mut self` method on param | `write` |
| `return param` (owned) | `escape_value` |
| Passing param to function with `consume/escape_value` effect | transitive effect |
| `let y = param` (local move) | `consume` |
| `return &param.field` | `escape_view` |
| `x = param` (rebinding) | nothing on the effect of the original param place |

**Key implementation challenge**: tracking which parameter a sub-expression "originates from" for escape_view. This requires a "value provenance" or "origin set" alongside types during expression checking.

### 4c. Call-Site Effect Checking

**src/SemaCheck.w**: At call sites, look up the callee's effect summary for each argument:

```
for each arg at call site:
    effects = callee.param_effects[i]
    is_copy_type = arg_type.is_copy
    call_mode = COPY if NK_COPY_ARG else MOVE if NK_MOVE_ARG else DEFAULT

    if effects & (EFF_CONSUME | EFF_ESCAPE_VALUE):
        if not is_copy_type and call_mode == DEFAULT:
            error: "non-Copy type used where callee may consume/escape; use `move x` or `copy x`"

    if effects & EFF_ESCAPE_VIEW:
        // view-origin tracking (Phase 5)

    if effects & EFF_WRITE:
        // register exclusive borrow during call duration
        // conflict with existing SHARED borrows on this place
```

### 4d. Export in Compiled Interface

Effects must be persisted alongside function type signatures so cross-module calls can be checked. Store effect vectors in the serialized type information.

### Tests
- `test/behavior/behav_eff_write.w`: callee with write effect; mutation visible at caller
- `test/behavior/behav_eff_escape.w`: callee with escape_value; requires move/copy
- `test/compile_errors/err_eff_escape_no_move.w`: non-Copy arg to escape_value function without move/copy

**Critical path note**: Phase 4 requires that all existing tests still pass (`make fixpoint`). Effect inference must be added conservatively — when a function's effects can't be fully computed (e.g., recursive or mutually recursive), assume worst case (all effects present) or use a fixpoint iteration.

---

## Phase 5: View-Origin Tracking for `escape_view`

This is lifetime inference without explicit annotations. When a function returns `&T`, track which parameter(s) the returned reference originates from.

### 5a. Origin Set Representation

During Phase 4 escape_view detection, when a reference is returned, record which parameters it may alias. This is a bitmask over parameter indices (up to 64 params covered with i64 origin mask).

### 5b. Call-Site Lifetime Checking

When `escape_view` effect is present, at the call site:
- The returned view's lifetime is the intersection of all origin parameter lifetimes
- If any origin parameter is invalidated (moved, goes out of scope) before the view is last used → error

This requires tracking view liveness: when `let v = f(x)`, `v` is a view into `x`. The borrow checker must reject use of `v` after `x` is moved or out of scope.

**Implementation**: Extend the existing borrow tracking to associate returned reference bindings with their origin symbols. When an origin is invalidated, all dependent views become invalid.

### Tests
- `test/compile_errors/err_escape_view_move_origin.w`: `f(move xs)` where f has `escape_view` → error
- `test/compile_errors/err_view_dangling.w`: view outlives origin → error
- `test/behavior/behav_escape_view_valid.w`: valid use of escaped view within origin lifetime

---

## Phase 6: Effect Pinning (`@[effect(...)]`)

### 6a. Attribute Parsing

**src/Parser.w** (around line 343–353 in `skip_attributes`/attribute parsing): Add `effect` to recognized attribute names. Parse `@[effect(param = effect_set)]` where effect_set is one of: `read`, `write`, `consume`, `escape_value`, `escape_view`, or `[effect, effect, ...]`.

**src/Ast.w**: Store parsed effect pins in function node extra data (or in the existing pending_attrs mechanism).

### 6b. Floor/Ceiling Enforcement

**src/SemaCheck.w**: After effect inference for a function body:
- **Floor check**: inferred effects must be ⊇ pinned effects. If inferred < pinned, error: "body doesn't satisfy pinned effect floor"
- **Ceiling check**: inferred effects must be ⊆ pinned effects. If inferred > pinned, error: "body exceeds pinned effect ceiling"

Also: the exported effect summary for a pinned function is the pinned set (not the inferred set), so downstream callers are checked against the pin.

### Tests
- `test/compile_errors/err_pin_floor.w`: body doesn't satisfy pinned floor
- `test/compile_errors/err_pin_ceiling.w`: body exceeds pinned ceiling
- `test/behavior/behav_effect_pin.w`: pinned function with future-reserved write

---

## Implementation Order and Dependencies

```
Phase 1 (copy/move syntax)    — no dependencies, start here
    ↓
Phase 2 (Copy tracking)       — needed for Phase 1 semantics
    ↓
Phase 3 (receiver modes)      — can be done alongside Phase 1/2
    ↓
Phase 4 (effect summaries)    — depends on Phase 1-3; largest work
    ↓
Phase 5 (view-origin)         — depends on Phase 4
    ↓
Phase 6 (effect pinning)      — depends on Phase 4
```

Each phase must individually pass:
```
make build && make fixpoint && make test
```

---

## Critical Files

| File | Phases | Key Changes |
|---|---|---|
| `src/Token.w` | 1 | Add TK_KW_COPY |
| `src/Ast.w` | 1,3 | NK_COPY_ARG, NK_MOVE_ARG, FN_PARAM_FLAG_REF_SELF, FN_PARAM_FLAG_MOVE_SELF |
| `src/Parser.w` | 1,3,6 | Call-site copy/move parsing; receiver mode flags; effect attribute |
| `src/Sema.w` | 2,4 | Copy flag in type descriptors; effect set Vecs |
| `src/SemaCheck.w` | 1,2,3,4,5,6 | Bulk of semantic enforcement |
| `src/MIR.w` | 1 | Lower NK_COPY_ARG / NK_MOVE_ARG |
| `src/Codegen.w` | 1 | Codegen for copy/move args (Clone call if needed) |

---

## Verification

Full end-to-end verification after each phase:
1. `make build` — compiler compiles
2. `make fixpoint` — stage2 == stage3 (nondeterminism check)
3. `make test` — no regressions
4. New tests in `test/behavior/behav_mut_md_*.w` and `test/compile_errors/err_mut_md_*.w`

The hardest fixpoint risk is Phase 4 (effect inference), because any nondeterminism in effect computation (e.g., HashMap iteration order) will break fixpoint. Use parallel Vec arrays for effect storage, not HashMap — same pattern used for `try_eval_const_int` in memory.
