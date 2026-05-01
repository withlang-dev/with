# P6 Design: NLL View-Liveness via BorrowCfg

Design document for implementing non-lexical-lifetime (NLL) view-liveness
analysis, per docs/mut.md Rev 8 §8.4.

**Revision 2** — revised after verification trace against SemaCheck.w
discovered false negatives in branching and loop cases.

---

## 1. What the spec requires

**§8.4 Rule:** A live `&T` view of a place creates an obligation: no mutation
may occur to that place (or any overlapping projection) while the view is live.
The view is live from its creation until its last use (non-lexical liveness).

**§8.4 Liveness semantics:** "The view is live until its last use. After the
last use, mutation of the underlying place becomes legal again. This is
non-lexical liveness, equivalent to Rust's NLL semantics."

**§8.4 Scope:** "This rule is the only borrow-checker-shaped analysis in v1.
It does not require lifetime variables, region inference, or annotations. The
compiler tracks per-place view liveness through scopes."

**§15.6 Diagnostic:** Three-location report — view creation site, mutation
site, last-use site.

---

## 2. What already exists

### 2a. Borrow tracking infrastructure (SemaCheck.w)

The borrow checker operates during sema, on the AST (not MIR). Core state:

- `borrow_kinds: Vec[i32]` — SHARED or EXCLUSIVE per borrow
- `borrow_places: Vec[i32]` — root place symbol per borrow
- `borrow_fields: Vec[i32]` — field discrimination
- `borrow_refs: Vec[i32]` — named reference symbol (0 = unnamed temporary,
  -1 = iterator sentinel)
- `borrow_path_starts/counts + borrow_path_data` — field-path chain for
  disjoint-path checks via `are_borrows_disjoint_paths`

### 2b. NLL-equivalent expiry (SemaCheck.w:7610)

`expire_dead_borrows_in_block` provides NLL-equivalent behavior for
**straight-line code within a single block** by scanning forward through
the remaining statements + tail. For each named borrow, it calls
`expr_uses_symbol` recursively through the remaining AST. If no future
use is found, the borrow is removed.

### 2c. check_mutation_against_views (SemaCheck.w:6835)

When a mutation is detected, `check_mutation_against_views` scans the active
borrow table for SHARED borrows on overlapping places. Uses disjoint-path
analysis to avoid false positives on independent field projections.

Currently emits a single-location warning. The spec requires a three-location
diagnostic (§15.6).

### 2d. BorrowCfg.w stub (227 lines)

CFG construction from AST expression subtrees. Handles block, if, while, loop,
return, break, goto. Does NOT handle match or for. Builds CfgGraph with
CfgNode + CfgEdge, but no dataflow analysis runs on it.

### 2e. Closure capture + §15.7/§15.8

Closure capture conflict detection and iterator-specific diagnostics are
implemented separately, using the borrow table plus `expr_uses_symbol`.

---

## 3. Verification findings (Rev 2)

The Rev 1 design claimed "the core NLL analysis already exists" and no
separate handling was needed for branching or loops. **This was wrong.**
Verification against the actual code revealed two false-negative bugs.

### 3.1 Straight-line NLL — CORRECT

Test case:
```
let first = &xs[0]    // stmt 0: borrow created, ref=first
print(first)           // stmt 1: uses first
                       // expire_dead_borrows_in_block: scans fwd, xs.push doesn't use first → EXPIRED
xs.push(42)            // stmt 2: mutation — no conflict (correct, first already expired)
```

`expire_dead_borrows_in_block` correctly computes last-use within a single
block's linear statement sequence. No change needed.

### 3.2 Branching — FALSE NEGATIVE BUG

Test case:
```
let first = &xs[0]    // outer block stmt 0: borrow created
if condition:
    pass               // then body: expire_dead_borrows_in_block runs,
                       //   no use of first in remaining then stmts → EXPIRED
else:
    xs.push(42)        // borrow already removed → NO WARNING (wrong!)
print(first)           // view used here — should conflict with xs.push
```

**Root cause:** `check_if_expr` (SemaCheck.w:2377) calls `check_expr` on the
then-body and else-body sequentially with NO save/restore of the borrow table.
The then-body's inner `check_block` runs `expire_dead_borrows_in_block`, which
operates on ALL borrows regardless of which scope created them. The then-body's
block finds no remaining uses of `first` within itself, so it expires the
borrow. The else-body then sees the borrow table without `first`, and the
mutation goes undetected.

The outer block's expiry pass (after the entire if-expr) would have correctly
kept the borrow alive (because `print(first)` follows the if). But the inner
block's expiry already removed it before the outer block gets a chance.

### 3.3 Loops — FALSE NEGATIVE BUG

Test case:
```
let first = &xs[0]    // outer block: borrow created
while condition:
    print(first)       // loop body stmt 0: uses first
                       // expire_dead_borrows_in_block: scans fwd in body,
                       //   xs.push doesn't use first → EXPIRED
    xs.push(42)        // borrow removed → NO WARNING (wrong!)
                       // next iteration: print(first) re-executes but borrow gone
```

**Root cause:** Same as branching — the loop body's `check_block` runs
`expire_dead_borrows_in_block` on the global borrow table. After `print(first)`,
it scans the remaining body stmts. `xs.push(42)` doesn't use `first`, so the
borrow is expired. The back-edge (loop re-execution) is invisible to the
forward scan.

`check_while` (SemaCheck.w:1462) and `check_for` (SemaCheck.w:2554) check
the body exactly once with no borrow table save/restore.

### 3.4 §15.6 diagnostic — MISSING INFRASTRUCTURE

`check_mutation_against_views` emits:
```
self.emit_warning("cannot mutate place: a read-only view of it is still live (§15.6)", err_node)
```

Single location (mutation site only). Missing:
- Borrow creation node (not stored in borrow table)
- Last-use node (no finder implemented)
- Multi-span diagnostic emission

---

## 4. Design: scoped borrow expiry

### 4.1 Core principle

**Borrows should only be expired by the block that "owns" them** — the block
at whose scope level they were created. Inner blocks (branch bodies, loop
bodies) must not expire borrows from outer scopes, because they lack the
outer context needed to determine true last-use.

### 4.2 Mechanism: borrow scope depth

Add a parallel Vec to the borrow table:

- `borrow_scope_depths: Vec[i32]` — set to `self.scope_depth` when the
  borrow is created.

Add a `scope_depth: i32` counter to Sema (if not already present), incremented
by `push_scope()`, decremented by `pop_scope()`.

**Modified `expire_dead_borrows_in_block`:** When iterating borrows for
potential expiry, skip any borrow where `borrow_scope_depths[i] < current_scope_depth`.
Only expire borrows owned by the current scope or deeper.

**Modified `remove_borrow_at`:** Mirror `borrow_scope_depths` in the swap-remove
logic (same as all other parallel Vecs).

### 4.3 Why this fixes branching

```
let first = &xs[0]    // scope_depth=1, borrow created with depth=1
if condition:
    push_scope()       // scope_depth=2
    pass
    // expire: first has depth 1, current depth 2 → 1 < 2 → SKIP
    pop_scope()        // scope_depth=1
else:
    push_scope()       // scope_depth=2
    xs.push(42)        // first still in table → CONFLICT DETECTED ✓
    pop_scope()        // scope_depth=1
print(first)
// outer expire: first has depth 1, current depth 1 → 1 >= 1 → eligible
// print(first) uses first → stays alive
```

### 4.4 Why this fixes loops

```
let first = &xs[0]    // scope_depth=1, borrow created with depth=1
while condition:
    push_scope()       // scope_depth=2
    print(first)
    // expire: first has depth 1, current depth 2 → SKIP
    xs.push(42)        // first still in table → CONFLICT DETECTED ✓
    pop_scope()        // scope_depth=1
```

### 4.5 Borrows created within inner scopes still expire correctly

```
if condition:
    push_scope()       // scope_depth=2
    let v = &xs[0]     // borrow created with depth=2
    print(v)
    // expire: v has depth 2, current depth 2 → 2 >= 2 → eligible
    //   no remaining uses → EXPIRED
    xs.push(42)        // v already expired → no conflict ✓
    pop_scope()
```

### 4.6 Conservative but safe

This approach is more conservative than full NLL for some cases:

```
let first = &xs[0]
if condition:
    print(first)       // last use of first on this path
else:
    // first not used on this path
xs.push(42)            // is first live here?
```

Under full NLL: `first` is not live at `xs.push(42)` because there is no
path from `xs.push(42)` to a future use of `first`. The mutation should
be allowed.

Under scoped expiry: `first`'s borrow has outer scope depth. The outer
block's `expire_dead_borrows_in_block` after the if-expr scans forward —
no remaining stmts use `first`. So the borrow IS expired before
`xs.push(42)`. **This case is handled correctly.**

The only conservatism: borrows from outer scopes cannot be expired WITHIN
inner blocks, even if there is no use after the inner block. They can
only be expired after the inner block completes, when the outer block's
expiry runs. This is a timing difference, not a correctness difference —
the outer expiry will still remove dead borrows at the next statement
boundary.

---

## 5. Design: §15.6 three-location diagnostic

### 5.1 Store creation node

Add `borrow_creation_nodes: Vec[i32]` to the borrow table. Populate in
`check_borrow_create` and `check_borrow_create_direct` with the `err_node`
parameter. Mirror in `remove_borrow_at`.

### 5.2 Find last-use node

Add `Sema.find_last_use_in_block(block_extra_start, stmt_count,
start_index, tail_node, sym) -> i32`. Returns the AST node ID of the
last statement that uses `sym`, or 0. Variant of the forward scan in
`expire_dead_borrows_in_block` — instead of removing, returns the last
matching node.

At conflict time, `check_mutation_against_views` needs the enclosing
block's coordinates. Store them in Sema fields:
- `current_block_extra_start: i32`
- `current_block_stmt_count: i32`
- `current_block_stmt_index: i32`
- `current_block_tail: i32`

Set at the start of `check_block`'s statement loop. Updated at each
iteration (stmt_index tracks the current position).

### 5.3 Diagnostic emission

When conflict is found:
1. Creation node: `borrow_creation_nodes[i]`
2. Mutation node: `err_node` parameter
3. Last-use node: `find_last_use_in_block(...)` from mutation point forward

Emit format per §15.6:
```
error: cannot mutate `xs` while read-only view `first` is live
  --> example.w:4:5
   |
3  |     let first = &xs[0]
   |                 ------ view created here
4  |     xs.push(1)
   |     ^^^^^^^^^^ mutation conflicts with live view
5  |     print(first)
   |           ----- view used here
```

For the three-location diagnostic, use `emit_warning` with the mutation
node as primary, plus two secondary annotations. If the diagnostic system
doesn't support multi-span, emit as:

```
warning: cannot mutate `xs` while read-only view `first` is live (§15.6)
note: view `first` created here  [creation node span]
note: view `first` used here     [last-use node span]
```

### 5.4 Fallback when last-use is in a different block

If `find_last_use_in_block` returns 0 (the use is inside a nested
block — e.g., inside an if-body that the flat scan can't see), fall
back to the two-location diagnostic (creation + mutation) without the
last-use annotation. This is acceptable for P6; full AST-recursive
last-use finding can be added later.

---

## 6. Implementation plan

### 6.1 Add borrow_scope_depths + borrow_creation_nodes

Add two new parallel Vecs to Sema's borrow table. Add `scope_depth: i32`
counter. Populate both in `check_borrow_create`, `check_borrow_create_direct`.
Mirror in `remove_borrow_at`.

Files: `src/Sema.w`, `src/SemaCheck.w`.

### 6.2 Scope the expiry in expire_dead_borrows_in_block

Add the scope-depth guard: skip borrows where `borrow_scope_depths[i]`
is less than the current `scope_depth`. This is a one-line condition
added to the existing while loop.

File: `src/SemaCheck.w` (line ~7612).

### 6.3 Add block context tracking for §15.6

Add `current_block_extra_start`, `current_block_stmt_count`,
`current_block_stmt_index`, `current_block_tail` fields to Sema.
Set them in `check_block`'s statement loop.

File: `src/Sema.w`, `src/SemaCheck.w`.

### 6.4 Implement find_last_use_in_block

Forward-scan variant of `expire_dead_borrows_in_block` that returns the
last node using a symbol instead of removing the borrow.

File: `src/SemaCheck.w`.

### 6.5 Upgrade check_mutation_against_views diagnostic

Replace single-location warning with three-location diagnostic using
creation node, mutation node, and last-use node.

File: `src/SemaCheck.w` (line ~6859).

### 6.6 Add §18 test cases

Test files under `test/`:
- `test/mut_view_liveness.w` — straight-line accepted/rejected cases
- `test/mut_view_branch.w` — branching cases (borrow survives branches)
- `test/mut_view_loop.w` — loop cases (borrow survives loop body)
- `test/mut_view_disjoint.w` — disjoint field paths accepted

### 6.7 Promote to errors (deferred to P12)

`emit_warning` → `emit_error` gated behind STRICT_VIEWS sentinel.
P6 ships with warnings. P12 flips.

---

## 7. What P6 does NOT do

- **Full CFG-based dataflow.** Not needed. Scoped expiry handles the
  false-negative cases without building a separate CFG. The BorrowCfg.w
  stub remains for future optimization.
- **Branch-sensitive precision.** If a borrow is only used in one branch,
  the other branch could theoretically allow mutation. Scoped expiry
  does not optimize this — it keeps the borrow alive until the outer
  block's expiry runs. This is conservative but safe.
- **Mutable borrow tracking.** The spec removed `&mut`. Only read-only
  views (`&T`) need liveness.
- **Lifetime parameters or region inference.** Excluded from v1.
- **Cross-function analysis.** Scoped to the enclosing function.

---

## 8. Risk assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Scoped expiry too conservative — rejects valid programs | Medium | Conservative is safe; tighten with CFG later |
| scope_depth counter out of sync | Low | Mirror push_scope/pop_scope exactly |
| remove_borrow_at swap-remove breaks new parallel Vecs | Low | Same pattern as existing 6 Vecs — mechanical |
| Block context fields stale at conflict time | Medium | Set at every check_block iteration; test explicitly |
| Existing tests regress from tighter expiry rules | Low | Scoped expiry only keeps borrows alive LONGER, never shorter — can't cause new false positives |

---

## 9. Interaction with existing systems

### 9.1 §15.7/§15.8 closure diagnostics

These check conflicts at closure CALL sites, not at mutation statement sites.
Complementary to §15.6. P6 does not change them.

### 9.2 BorrowCfg.w stub

Keep as-is. The scoped-expiry approach makes it unnecessary for P6's
correctness, but the CFG infrastructure remains available for future
branch-sensitive precision improvements.

### 9.3 Unnamed temporary borrows

`expire_dead_borrows_in_block` removes unnamed temporaries (ref_sym == 0)
at every statement boundary regardless of scope depth. This behavior is
correct — unnamed temporaries expire at the enclosing statement — and
the scope-depth guard should NOT apply to them. The guard condition
should be: `if ref_sym != 0 and borrow_scope_depths[bi] < scope_depth: skip`.

---

## 10. Open questions

1. **scope_depth field.** Does Sema already track scope depth, or only
   a scope stack? If no counter exists, add one. If one exists, reuse it.
   **Action:** grep for `scope_depth` in Sema.w before implementing.

2. **Multi-span diagnostics.** Does the diagnostic system support multiple
   spans per diagnostic? If not, emit as primary + notes.
   **Action:** check `emit_error` / `emit_warning` signatures.

3. **Pop-scope cleanup.** When `pop_scope` runs, should it forcibly remove
   all borrows created at that scope depth? Currently borrows "leak" into
   outer scopes. With scope-depth tracking, we could clean up on pop.
   **Recommendation:** yes — add cleanup in `pop_scope` that removes
   borrows with `borrow_scope_depths[i] == scope_depth`. This prevents
   stale borrows from accumulating.
