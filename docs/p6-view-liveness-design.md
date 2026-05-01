# P6 Design: NLL View-Liveness via BorrowCfg

Design document for implementing non-lexical-lifetime (NLL) view-liveness
analysis, per docs/mut.md Rev 8 §8.4.

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

`expire_dead_borrows_in_block` already provides NLL-equivalent behavior by
scanning forward through the remaining statements + tail of the current block.
For each named borrow (borrow_refs[i] != 0), it calls `expr_uses_symbol`
recursively through the remaining AST. If no future use is found, the borrow
is removed.

This handles:
- Last use earlier in same block, then mutation: borrow expired.
- Last use inside an if/while/loop body, then post-block mutation.
- Last use across nested scopes (expr_uses_symbol recurses into all branches).

What it does NOT handle (per the BorrowCfg.w header comment):
- Branch-divergent uses where only some paths use the ref.
- Loop-iteration carry of borrows through the back-edge.
- Precise dataflow when calls might transitively use the ref.

### 2c. check_mutation_against_views (SemaCheck.w:6835)

When a mutation is detected (assignment, mutating receiver call, `push`/`pop`),
`check_mutation_against_views` scans the active borrow table for SHARED borrows
on overlapping places. Uses disjoint-path analysis to avoid false positives on
independent field projections (e.g., `user.age` does not overlap `user.name`).

Currently emits warnings (P7-P11); promoted to errors at P12.

### 2d. BorrowCfg.w stub (227 lines)

CFG construction from AST expression subtrees. Handles block, if, while, loop,
return, break, goto. Does NOT handle match or for. Builds CfgGraph with
CfgNode + CfgEdge, but no dataflow analysis runs on it.

### 2e. Closure capture + §15.7/§15.8

Closure capture conflict detection (`check_closure_capture_conflict`,
`check_for_closure_conflict`) and iterator-specific diagnostics are
implemented separately, using the borrow table plus `expr_uses_symbol`
to determine whether a captured variable remains live after the closure call.

---

## 3. Design questions and answers

### 3.1 Representation: what level does the analysis run on?

**Answer: AST, within sema. Not MIR.**

Rationale:
1. The existing borrow tracker operates entirely at sema time on the AST.
   Borrow creation, conflict checking, and expiry all happen during the
   expression-checking walk in `check_expr`/`check_block`.
2. MIR lowering happens after sema. Moving borrow checking to MIR would
   require: (a) tracking borrow creation/expiry in MIR, (b) mapping MIR
   errors back to source locations, (c) duplicating place analysis. None
   of this is needed — the spec's requirements are satisfiable at the AST
   level.
3. The spec explicitly says "the compiler tracks per-place view liveness
   through scopes" — this is a natural fit for AST-level scope-tracking.

The P6 analysis stays in SemaCheck.w, extending the existing
`expire_dead_borrows_in_block` to handle control flow more precisely.

### 3.2 CFG construction

**Answer: P6 does NOT build a separate CFG.**

The existing `expire_dead_borrows_in_block` + `expr_uses_symbol` approach
is fundamentally sound and already handles all linear and nested-scope cases.
The "gaps" (branch-divergent uses, loop carry) are real but narrow:

**Branch-divergent uses.** Currently, `expr_uses_symbol` returns 1 if the
symbol appears in ANY branch of an if/match. This is conservative — it
keeps the borrow alive even if only one branch uses it. The NLL-correct
behavior is: a borrow is live at a point if there EXISTS any execution path
from that point to a use. The current `expr_uses_symbol` already computes
exactly this (existential reachability) because it recurses into both
branches and returns 1 if either has the symbol. So branch-divergent
uses are **already handled correctly**.

**Loop carry.** A borrow created inside a loop body whose last use is also
inside the loop should expire at the end of each iteration (the next
iteration may re-create it). The current code expires borrows at statement
boundaries within the containing block. For borrows created inside a
while/for body, the borrow is scoped to the loop body block; it's created
and expired within that block's statement walk. So loop-carry is **already
handled correctly** for the common case (borrow created inside the loop).

The case NOT handled: a borrow created BEFORE a loop, used INSIDE the loop.
The current `expr_uses_symbol` sees the use inside the loop and keeps the
borrow alive. This is **overly conservative** (it keeps the borrow alive
for the entire loop even if only the first iteration uses it), but it is
**safe** — it rejects more programs than necessary, never fewer.

**Decision:** The BorrowCfg.w stub can stay as scaffolding for future
refinement (branch-divergent optimization), but P6 does not require it.
P6 extends the existing AST-walking approach.

### 3.3 Dataflow

**Answer: No explicit dataflow fixpoint. The existing forward scan is
equivalent.**

The spec requires "last use" computation. For each borrow, we need to know:
is there any future use of the borrow's reference symbol from the current
program point?

`expr_uses_symbol` already computes this as an AST recursive walk. It is
a forward existential reachability query: "does symbol S appear anywhere
in the subtree rooted at node N?" The walk handles all AST node kinds
including nested blocks, if/else branches, while/for bodies, match arms,
closures, and function calls.

The analysis does NOT need:
- A fixpoint iteration (no loops in the "use reaches back to borrow"
  direction — the AST walk is acyclic).
- A meet operator (we're computing existential reachability, not a
  lattice join).
- Transfer functions (no abstract state flows through program points;
  we just test "is symbol mentioned?").

This is simpler than classical NLL because the spec's §8.4 rule is simpler
than Rust's full borrow checker: there are no mutable borrows to track
(mutable access is always direct, never through references), no lifetime
parameters, no region inference. The only question is "is this read-only
view still used?"

### 3.4 Place identity

**Answer: Use the existing borrow_places + borrow_path infrastructure.**

The borrow tracker already represents places via:
- `borrow_places[i]`: the root symbol (intern pool ID).
- `borrow_path_starts[i]` + `borrow_path_counts[i]`: field-path chain
  into `borrow_path_data`, representing `.field1.field2` projections.

Overlapping-place detection uses `are_borrows_disjoint_paths`: two borrows
overlap unless their field paths diverge at some common prefix. This handles:
- Same root, same path: overlapping (e.g., `&xs` vs `xs.push()`).
- Same root, disjoint paths: non-overlapping (e.g., `&user.name` vs
  `user.age = 31`).
- Prefix containment: `&user` overlaps `user.name` (parent contains child).

Index projections are not path-tracked (no field symbol for `xs[0]`). Under
the current system, `&xs[i]` creates a borrow on root `xs` with no path
extension, so ANY mutation of `xs` conflicts. This is conservative but safe
and matches the spec's §8.1 ("any modification to a container may
invalidate index-derived views").

No changes needed for P6. The place identity system is adequate.

### 3.5 Conflict detection and the §15.6 diagnostic

**Current state:** `check_mutation_against_views` emits a single-location
warning: "cannot mutate place: a read-only view of it is still live (§15.6)".
The spec requires a three-location diagnostic showing (1) where the view was
created, (2) where the mutation occurs, (3) where the view is last used.

**What P6 adds:** Store the view creation site in the borrow table and
compute the last-use site at conflict time. Specifically:

1. **Borrow creation span.** Add `borrow_creation_nodes: Vec[i32]` to the
   borrow table, storing the AST node ID where the `&` expression was
   checked. This is already available in `check_borrow_create` — the
   `err_node` parameter is the `&` expression.

2. **Last-use site.** When `check_mutation_against_views` finds a conflict,
   it has the mutation node. To find the last-use node, scan forward from
   the mutation point using a variant of `expr_uses_symbol` that returns
   the last-seen node ID instead of just 0/1. This is a
   `find_last_use_of_symbol` walk.

3. **Diagnostic format.** Per §15.6:
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

   The borrow table provides: root place name (`borrow_places[i]`),
   reference name (`borrow_refs[i]`), creation node (new). The mutation
   node is the `err_node` parameter. The last-use node comes from the
   forward scan.

### 3.6 §18 rejected cases coverage

| Case | Mechanism | P6 change needed? |
|---|---|---|
| `view_then_mutate` (accepted) | `expire_dead_borrows_in_block` removes borrow before mutation | No — already works |
| `bad_mutate_while_view_live` (rejected) | `check_mutation_against_views` sees live borrow | No — already fires (as warning) |
| `bad_push_with_view` (rejected, §5.5) | Argument independence check in `check_method_call` | No — already implemented |
| `bad_push_with_iter` (rejected, §5.5) | Iterator sentinel in borrow_refs (-1) | No — already implemented |
| `bad_capture_with_arg` (rejected, §9) | Closure capture conflict checking | No — already implemented |
| `bad_capture_with_view` (rejected, §9) | Closure capture with borrow_refs check | No — already implemented |
| `bad_capture_with_iter` (rejected, §9) | Iterator-specific closure capture (§15.8) | No — already implemented |
| Disjoint field paths (accepted) | `are_borrows_disjoint_paths` | No — already works |
| Branch-divergent last use | `expr_uses_symbol` existential walk | No — already correct |
| Loop-carried borrow | Block-scoped borrow + statement-boundary expiry | No — already correct (conservative) |

**Conclusion:** The core analysis is already implemented. P6's contribution
is upgrading the diagnostic quality (three-location report) and promoting
the existing warnings to errors.

### 3.7 Interaction with existing §15.7/§15.8 diagnostics

The existing closure capture diagnostics (§15.7 "capture conflict", §15.8
"iterator-specific") operate at a different level than view-liveness:

- **§15.7/§15.8** check conflicts at closure CALL sites — "you can't pass
  `xs` to a closure that captures `xs` mutably while also passing `&xs[0]`
  as a sibling argument."
- **§8.4/§15.6** checks conflicts at mutation STATEMENT sites — "you can't
  call `xs.push()` while `&xs[0]` is live."

They are complementary, not overlapping. §15.7/§15.8 fire at `check_call_args`
time. §15.6 fires at `check_method_call` + `check_assign` time. P6 does not
change §15.7/§15.8; they continue to run alongside.

### 3.8 Interaction with the BorrowCfg.w stub

**Answer: keep the stub as-is.** It provides CFG construction for future
optimization (tightening the analysis for branch-divergent cases). P6 does
not require it because the existing `expr_uses_symbol` walk is equivalent
for the spec-required cases.

The stub is 227 lines of working code — it correctly builds CFGs for block,
if, while, loop. Deleting it would lose that scaffolding for no benefit.
If a future phase needs to tighten the analysis (e.g., accepting a program
where a borrow is used in only one branch of an if), the CFG infrastructure
is ready.

---

## 4. Implementation plan

P6 is smaller than anticipated. The core NLL analysis already exists. The
work is:

### 4.1 Add borrow creation node to the borrow table

Add `borrow_creation_nodes: Vec[i32]` in Sema. Populate it in
`check_borrow_create` and `check_borrow_create_direct` with the `err_node`
parameter.

Files: `src/Sema.w` (add field), `src/SemaCheck.w` (populate in both
creation functions + mirror in `remove_borrow_at`).

### 4.2 Implement find_last_use_of_symbol

Add `Sema.find_last_use_in_block(block_extra_start, stmt_count,
start_index, tail_node, sym) -> i32` returning the AST node ID of the
last statement/expression that uses `sym`, or 0 if none. This is a variant
of the forward scan in `expire_dead_borrows_in_block` that returns the node
instead of just removing the borrow.

File: `src/SemaCheck.w`.

### 4.3 Upgrade check_mutation_against_views diagnostic

When a conflict is found, look up the creation node from
`borrow_creation_nodes[i]`, compute the last-use node via
`find_last_use_in_block`, and emit the three-location diagnostic matching
the §15.6 format.

This requires access to the enclosing block's extra_start/stmt_count at
conflict-detection time. Currently `check_mutation_against_views` doesn't
have this context. Options:
- Thread it through as parameters (cleanest).
- Store the current block context in Sema fields (simpler, since the
  block walk already tracks this).

File: `src/SemaCheck.w`.

### 4.4 Promote warnings to errors

Flip the `emit_warning` calls in `check_mutation_against_views` to
`emit_error`. This is gated behind `STRICT_VIEWS` (the P12 sentinel),
so it can be flipped incrementally:
- P6 ships with STRICT_VIEWS = 0 (warnings).
- P7 verifies no warnings in src/lib/rt.
- P12 flips to 1 (errors).

### 4.5 Add §18 test cases

Add test files under `test/` covering:
- `view_then_mutate` — accepted (view expired before mutation).
- `bad_mutate_while_view_live` — rejected with §15.6 diagnostic.
- Disjoint field paths — accepted.
- Branch-divergent last use — accepted (conservative is fine).

These validate that the existing analysis + improved diagnostic work
correctly. Many of these cases already work; the tests make the coverage
explicit.

---

## 5. What P6 does NOT do

- **Full CFG-based dataflow.** Not needed. The AST walk is equivalent for
  the spec's requirements. A future optimization pass could use BorrowCfg
  to tighten branch-divergent cases.
- **Mutable borrow tracking.** The spec removed `&mut`. There are no
  mutable borrows to track. Only read-only views (`&T`) need liveness.
- **Lifetime parameters or region inference.** The spec explicitly excludes
  these from v1.
- **Cross-function analysis.** The spec's rule is scoped to "within the
  enclosing scope." No interprocedural analysis.

---

## 6. Risk assessment

| Risk | Severity | Mitigation |
|---|---|---|
| False positives from overly conservative `expr_uses_symbol` | Low | Conservative is safe; tighten later with CFG |
| Missing creation-node tracking breaks existing code | Low | Additive field; default 0 is safe |
| §15.6 three-location diagnostic requires block context | Medium | Thread block context through check_mutation_against_views |
| Existing tests break when warnings are promoted | Low | Gated behind STRICT_VIEWS sentinel |

---

## 7. Open questions

1. **Block context threading.** Should `check_mutation_against_views` receive
   the enclosing block's AST coordinates as parameters, or should Sema store
   the current block in a field? The field approach is simpler but adds state.
   **Recommendation:** store in Sema field (`current_check_block_extra_start`,
   `current_check_block_stmt_count`, `current_check_block_stmt_index`,
   `current_check_block_tail`) — set at the start of `check_block`, used by
   `check_mutation_against_views`. This mirrors how `current_ret_type` is
   managed.

2. **find_last_use granularity.** Should the last-use search return the
   innermost expression node (e.g., `first` in `print(first)`), or the
   containing statement (e.g., `print(first)`)? The §15.6 diagnostic example
   shows `view used here` pointing at `first`, suggesting the innermost
   expression. But the forward scan operates at statement granularity.
   **Recommendation:** return the statement node, then let the diagnostic
   renderer extract the symbol mention within it for the secondary span.

3. **Loop-pre-borrow tightening.** A borrow created before a loop, used
   only in the first iteration, is kept alive for the entire loop. This is
   conservative but safe. Is it worth tightening for P6?
   **Recommendation:** no. The spec says nothing about loop-iteration
   precision. Ship the conservative version; tighten in a future pass if
   user feedback warrants it.
