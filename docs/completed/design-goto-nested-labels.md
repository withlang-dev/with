# Design: Nested Label Lowering in Goto State Machine

> Historical design note: this document describes the removed
> `__pc`/`__goto_pending` lowering. Current goto lowering builds a
> migrator CFG, runs `std.cfg.stackify`, and emits labeled
> blocks/loops. Irreducible CFGs fail migration loudly instead of
> falling back to a state machine.

## Scope of the Bug

Two interacting bugs prevent correct goto state machine lowering
for functions with nested labels:

**Bug A — Silent translation abort on labels inside do-while(0):**
In `ci_lower_stmt_goto_ir`, a LabelStmt whose body is a NullStmt
(e.g. `L_RM25:;`) returns 0. The CompoundStmt handler treats this
as a fatal error (line 7862) and aborts the entire subtree. This
cascades: do-while body fails → case body fails → switch drops the
case (fallthrough path) or returns 0 (no-fallthrough path). Also,
an empty `do{}while(0)` body (from `PCRE2_DEBUG_UNREACHABLE()`)
causes the DoStmt handler to return 0 (line 7960-7962), aborting
the default case.

**Bug B — Missing state arms for nested labels:**
`ci_lower_goto_body_structural` walks only direct children of the
function body. Labels nested inside loops, switches, or compound
blocks get state IDs from `ci_collect_labels` but no corresponding
case arms in the generated `match __pc` dispatch.

**Both bugs must be fixed together.** Bug A silently drops code
containing macro-expanded labels. Bug B prevents the labels that
survive from having state arms. The combined effect: case bodies
with RMATCH are dropped (Bug A), AND the labels those cases
reference have no arms (Bug B).

**Affected files** (targets with no matching arm):

| File | Missing states | Total labels |
|------|---------------|-------------|
| pcre2_match.w | 3,10,27,53,59,60,61,64,70,78 | ~88 (incl. L_RM) |
| pcre2_dfa_match.w | 3,4,6,7,9 | ~11 |
| pcre2_compile.w | 7,8,9,10,11,12 | 21 |
| pcre2_study.w | 1,2 | ~4 |
| pcre2_convert.w | 1,2 | ~3 |

Additionally, in pcre2_match.w: the `switch(Freturn_id)` dispatch
table in the RETURN_SWITCH arm is silently dropped (Bug A: the
default case's `do{}while(0)` fails the no-fallthrough path), and
~72 case bodies in the main `switch(Fop)` that contain RMATCH
calls are silently dropped (Bug A: L_RM labels abort the case body
translation).

---

## Alternative Approaches

### A: Recursive arm lifting (selective inlining)

When a loop/switch body contains labels, "inline" the body into the
state machine: each nested label becomes a top-level state arm, and
the enclosing loop structure is replicated via state transitions.

**Pro:** Preserves structured loops for code that doesn't contain
labels (majority of code). Generated output is more readable and
closer to idiomatic With.

**Con:** Must handle every C construct that can contain labels:
for-loops, while-loops, do-while, switches, compound blocks, and
combinations thereof. Each construct needs special inlining logic.
The switch(Fop) inside for(;;) in match_() is particularly complex
because of fallthrough between case bodies, labels interleaved with
case labels, and the RMATCH/RRETURN macro-generated do-while(0)
wrappers containing L_RM labels.

### B: Full body flattening (discard structured loops)

When a function has ANY goto labels, flatten the entire function body
into a single flat state machine. Every statement becomes part of a
state arm. Loops are converted to state transitions (loop-back becomes
`__pc = loop_top_state; continue`). Switches become cascaded if-else
or match expressions inside state arms.

**Pro:** Simpler to implement correctly. One algorithm handles all
cases. No need for per-construct inlining logic. Correctness is
easier to verify because the transformation is uniform.

**Con:** Generated output is larger and less readable. Every loop
becomes a state transition even when no label is involved. The
match_() function would produce hundreds of state arms instead of
the ~90 it needs.

### C: Hybrid — flatten only subtrees that contain labels

Walk the function body. For subtrees that contain no labels, lower
them normally (structured loops, switches, etc). For subtrees that
DO contain labels, flatten them into state arms.

**Pro:** Best of both worlds. Code without labels stays structured.
Code with labels gets flattened correctly.

**Con:** Must detect the boundary between "needs flattening" and
"can stay structured." Must handle the transition at that boundary:
entering a flattened-subtree from a structured parent, and vice
versa.

### Recommended: Approach C (Hybrid) + Bug A fix

**Bug A fix** (prerequisite, in `ci_lower_stmt_goto_ir`):

1. CompoundStmt handler (line 7862): treat LabelStmt the same as
   NullStmt when its child returns 0. A label wrapping a null
   statement (like `L_RM25:;`) is semantically a no-op and should
   not abort the containing block.

2. DoStmt handler (line 7960-7962): treat an empty do-while body
   (empty CompoundStmt) as a no-op instead of aborting. `do{}while(0)`
   is a common C idiom for statement-wrapping macros and produces
   no code.

These two fixes unblock translation of RMATCH-containing case
bodies and the `switch(Freturn_id)` dispatch. Without them, Bug B's
fix is necessary but insufficient — the state arms would exist but
the code that transitions to them would still be silently dropped.

**Bug B fix** (Approach C):

The key observation is that in all 5 affected files, labels are
nested inside exactly one enclosing structure. In match_(), it's
`for(;;) { switch(Fop) { ...labels... } }`. The for(;;) has no
init/cond/inc. The switch is a pure dispatch.

The algorithm:

1. `ci_collect_labels` already finds all labels recursively. No
   change needed.

2. Add `ci_subtree_has_labels(session, cursor, label_map)` that
   returns true if any descendant of `cursor` is a LABEL_STMT
   whose name appears in `label_map`.

3. Modify `ci_lower_goto_body_structural` to recursively descend
   into children. When it encounters a non-label child:
   - If `ci_subtree_has_labels` is false: process normally via
     `ci_lower_stmt_goto_ir` (existing behavior).
   - If `ci_subtree_has_labels` is true: recursively descend
     into the child's children, flattening labels into state arms
     and converting loop/switch structures into state transitions.

4. The "recursive descent with flattening" must handle:
   - **for(;;)**: Create a synthetic "loop top" state. Emit init
     code into the current arm. When descending into the body,
     each label starts a new arm. At the bottom of the body (or
     on `break` from the switch), emit `__pc = loop_top; continue`.
   - **switch(expr)**: Emit the match expression. Case bodies that
     contain labels get their labels lifted. Case bodies that end
     in `break` get `__pc = after_switch; continue` (or just fall
     through to the next statement in the current arm).
   - **compound blocks**: Recursively descend.
   - **if/else**: Emit normally, but recurse into branches that
     contain labels.

---

# ARTIFACT 1: Expected State Machine for match_()

## Function structure in C

```
match() {
  // Frame setup (lines 687-748)
  goto NEW_FRAME;

  MATCH_RECURSE:           // top-level label
    // Allocate/grow heap frame (753-830)
    // Copy state into new frame
    // Fall through to NEW_FRAME

  NEW_FRAME:               // top-level label
    // Set up frame fields (849-880)
    // Fall through into for(;;)

    for (;;) {             // line 881 — THE OPCODE DISPATCH LOOP
      Fop = *Fecode;       // line 888
      switch (Fop) {       // line 889
        case OP_CLOSE: ...
        case OP_ASSERT_ACCEPT: ...
          // ~308 case labels, ~6000 lines of opcode handling
          // 11 named goto labels interleaved with case bodies:
          //   REPEATCHAR (1392), REPEATNOTCHAR (1733), REPEATTYPE (2973),
          //   REF_REPEAT (5278), POSSESSIVE_NON_CAPTURE (5545),
          //   POSSESSIVE_CAPTURE (5553), POSSESSIVE_GROUP (5557),
          //   GROUPLOOP (5676), ASSERT_NOT_FAILED (5853),
          //   SCS_OFFSET_FOUND (5907), ASSERT_NL_OR_EOS (6604)
          // 6 more nested labels: ENDLOOP00-03, ENDLOOP99, GOT_MAX
          // ~72 L_RM## labels (from RMATCH macro expansion)
          //   inside do{...}while(0) blocks within case bodies

        default: return PCRE2_ERROR_INTERNAL;
      }
      // No code between switch closing brace and for(;;) closing brace
      // break from switch falls through to here, loops back to Fop = *Fecode
    } // end for(;;), line 6897

    PCRE2_DEBUG_UNREACHABLE();

  RETURN_SWITCH:           // top-level label (line 6909)
    // Update last_used_ptr
    // If at top level, return rrc
    // Otherwise backtrack: F = previous frame
    switch (Freturn_id) {
      case 1: goto L_RM1;   // jump back INTO the for(;;)/switch
      case 2: goto L_RM2;
      ...
      case 39: goto L_RM39;
      // ... 68 total LBL entries
      default: return PCRE2_ERROR_INTERNAL;
    }
}
```

## Key control flow patterns

1. **Normal opcode execution**: `for(;;)` reads Fop, dispatches via
   switch, case body executes, case body ends with `break` (from
   switch) or `continue` (for the for-loop), both loop back to read
   the next opcode.

2. **Goto to nested label**: Some case bodies set up parameters then
   `goto REPEATCHAR` (etc). This jumps to the label, which is inside
   the switch body. After the label's code executes, it ends with
   `break` (from switch), which loops back to the for(;;) top.

3. **RMATCH (simulated recursion)**: Expands to:
   ```
   start_ecode = <ecode>;
   Freturn_id = RM##N;
   goto MATCH_RECURSE;    // → allocate frame, goto NEW_FRAME, re-enter for(;;)
   L_RM##N:;              // resume point after "recursive call" returns
   ```
   When the "recursive call" completes, RRETURN → RETURN_SWITCH →
   `switch(Freturn_id) { case N: goto L_RM##N; }` jumps back to the
   resume label.

4. **RRETURN (return from recursion)**: Sets `rrc = <value>`, then
   `goto RETURN_SWITCH`. RETURN_SWITCH either returns (if top level)
   or backtracks one frame and dispatches to the caller's L_RM label.

## Expected state machine structure

State IDs are assigned by DFS order of `ci_collect_labels_rec`. The
exact numbering depends on AST traversal order, but the structure is:

```
fn match_(start_eptr: ..., ...) -> c_int:
    // Hoisted variable declarations (all locals from all scopes)
    var __pc: i32 = 0
    var __goto_pending: i32 = 0

    while true {
        match __pc:

            0 =>  // ENTRY
                // Frame setup code (lines 687-748)
                // goto NEW_FRAME → __pc = <NEW_FRAME>; continue
                __pc = STATE_NEW_FRAME
                continue

            STATE_MATCH_RECURSE =>  // MATCH_RECURSE
                // Allocate/grow heap frame vector
                // Copy state into new frame
                // Fall-through → __pc = STATE_NEW_FRAME; continue
                __pc = STATE_NEW_FRAME
                continue

            STATE_NEW_FRAME =>  // NEW_FRAME
                // Set up frame fields
                // Fall-through into for(;;) → STATE_LOOP_TOP
                __pc = STATE_LOOP_TOP
                continue

            STATE_LOOP_TOP =>  // for(;;) loop entry: Fop = *Fecode
                (Fop = (unsafe: *Fecode))
                // switch(Fop) becomes match Fop:
                match Fop:
                    OP_CLOSE =>
                        // ... case body ...
                        // break from switch → loop back
                        __pc = STATE_LOOP_TOP
                        continue

                    OP_ASSERT_ACCEPT =>
                        // ... case body with RMATCH ...
                        // RMATCH(Fecode, RM1) becomes:
                        (start_ecode = Fecode)
                        (Freturn_id = 1)
                        __pc = STATE_MATCH_RECURSE
                        continue
                        // L_RM1 gets its own state arm (below)

                    // ... ~300 more case arms ...

                    _ =>  // default
                        return -44  // PCRE2_ERROR_INTERNAL

            STATE_L_RM1 =>  // L_RM1 (resume after RMATCH RM1)
                // Code that follows the RMATCH call in the source
                // Typically: check rrc, RRETURN or continue matching
                // When done, case body's "break" → loop back
                __pc = STATE_LOOP_TOP
                continue

            // ... STATE_L_RM2 through STATE_L_RM39, etc ...

            STATE_REPEATCHAR =>  // REPEATCHAR
                // Character repeat matching code
                // May contain RMATCH calls → __pc = STATE_MATCH_RECURSE
                // Ends with break from switch → loop back
                __pc = STATE_LOOP_TOP
                continue

            STATE_REPEATNOTCHAR =>  // REPEATNOTCHAR
                // Similar pattern
                __pc = STATE_LOOP_TOP
                continue

            // ... other nested labels ...

            STATE_GROUPLOOP =>  // GROUPLOOP
                // Group loop matching code
                __pc = STATE_LOOP_TOP
                continue

            STATE_RETURN_SWITCH =>  // RETURN_SWITCH
                // Update last_used_ptr
                if Frdepth == 0: return rrc
                // Backtrack one frame
                (F = (F as *mut c_char - F.back_frame) as *mut heapframe)
                (mb.cb.callout_flags |= PCRE2_CALLOUT_BACKTRACK)
                // switch(Freturn_id) dispatch:
                match Freturn_id:
                    1 => __pc = STATE_L_RM1; continue
                    2 => __pc = STATE_L_RM2; continue
                    // ... all 68 LBL entries ...
                    _ => return -44

            _ => break
    }
```

## Critical design points

### The for(;;) loop becomes a state

The `for(;;)` loop top becomes `STATE_LOOP_TOP`. This state reads
Fop and dispatches via a `match Fop:` expression. Each case body
that does NOT contain labels or gotos stays inline in the match arm.

### Case bodies with goto or labels become separate states

When a case body contains `goto REPEATCHAR`, the code up to the
goto stays inline in the case arm, and the goto becomes
`__pc = STATE_REPEATCHAR; continue`.

When a label (like REPEATCHAR) appears inside the switch body, it
becomes its own top-level state arm. The label's code runs, and when
it ends with `break` (from the switch), the arm transitions to
`STATE_LOOP_TOP` to re-read the next opcode.

### L_RM labels: each gets its own state

Each `L_RM##N` label created by RMATCH expansion becomes a state.
The RMATCH call becomes:
```
(start_ecode = <ecode>)
(Freturn_id = N)
__pc = STATE_MATCH_RECURSE
continue
```

The `L_RM##N` label becomes `STATE_L_RM##N`, containing the code
that follows the RMATCH call in the original C (typically checking
rrc and either RRETURN or continuing).

The RETURN_SWITCH dispatch (`switch(Freturn_id) { case N: goto L_RMN }`)
becomes `match Freturn_id: N => __pc = STATE_L_RMN; continue`.

### Break from switch vs break from for(;;)

In C, `break` inside a switch breaks the switch, not the enclosing
for(;;). In the state machine, both have the same effect: transition
to `STATE_LOOP_TOP` to re-enter the loop.

In C, `continue` inside the for(;;) (but outside the switch) jumps
to the for(;;) loop top. In the state machine, this is also
`__pc = STATE_LOOP_TOP; continue`.

There is no `break` from the for(;;) in match_(). The only way out
is via `return`, `goto RETURN_SWITCH`, or `goto MATCH_RECURSE`.

### Fallthrough between case bodies and labels

Several labels are preceded by case labels that fall through:

```c
case OP_NOTSTAR:
case OP_NOTSTARI:
...
    fc = *Fecode++ - ...;
    Lmin = rep_min[fc];
    Lmax = rep_max[fc];
    reptype = rep_typ[fc];

    REPEATNOTCHAR:    // fall-through from above cases
    GETCHARINCTEST(Lc, Fecode);
    ...
```

In the state machine, the case arms that fall through to the label
must explicitly transition: `__pc = STATE_REPEATNOTCHAR; continue`.
The migrator already handles goto-to-label as `__pc = N; continue`,
so this fallthrough is handled the same way: the case arm's code
ends with `__pc = STATE_REPEATNOTCHAR; continue` instead of a
switch-break.

### ENDLOOP00-03, ENDLOOP99, GOT_MAX

These are additional nested labels inside the for(;;)/switch. Same
treatment: each gets its own state arm, and control transitions to
`STATE_LOOP_TOP` when done (or to another state via goto).

### The do-while(0) wrappers

RMATCH expands to `do { ...; goto MATCH_RECURSE; L_RMN:; } while(0)`.
The `do { } while(0)` is a no-op wrapper. The migrator should:
- Translate the assignments and goto normally
- Create a state arm for L_RMN
- The while(0) condition means the loop executes exactly once, so
  the do-while can be elided

The current migrator already handles do-while(0) by treating it as
a block. The only issue is that it doesn't create a state arm for
the label inside the block.

### SCS_OFFSET_FOUND special case

SCS_OFFSET_FOUND is inside a `for(;;)` loop which is itself inside
the switch(Fop) case body for OP_ASSERT_SCS. The label is reached
by gotos from inside the inner for(;;). In the flattened model:
- The inner for(;;) gets its own "loop top" state
- SCS_OFFSET_FOUND becomes a state that contains the code after the
  inner loop, transitioning back to the outer STATE_LOOP_TOP when done

### ASSERT_NOT_FAILED special case

Similarly nested inside the OP_ASSERT_NOT case body, after an inner
for(;;) loop. Same treatment.

---

# ARTIFACT 2: C Construct Translation When Subtree Contains Labels

## Design decision: Hybrid approach

When `ci_subtree_has_labels` returns false for a node, use existing
`ci_lower_stmt_goto_ir` (no change). When it returns true, use the
new flattening logic described below.

For each construct below, I show the C source, the **wrong** current
output (labels discarded), and the **correct** expected output.

---

## for(init; cond; inc) { body-with-labels }

### Example C:

```c
void f() {
    setup();
    for (x = 0; x < 10; x++) {
        work(x);
        goto SKIP;
        middle(x);
        SKIP:
        finish(x);
    }
    cleanup();
}
```

### Where do init, cond, inc go?

- **init** (`x = 0`): emitted in the arm that precedes the loop.
  Then transition to `STATE_LOOP_COND`.
- **cond** (`x < 10`): emitted at `STATE_LOOP_COND`. If false,
  transition to `STATE_AFTER_LOOP`. If true, fall through to the
  loop body.
- **inc** (`x++`): emitted at the end of each arm that would
  "continue" the loop (either reaching the bottom of the body, or
  an explicit `continue` statement), before transitioning to
  `STATE_LOOP_COND`.

### How does "break" translate?

`break` from this for-loop → `__pc = STATE_AFTER_LOOP; continue`

### How does "continue" translate?

`continue` → execute inc (`x++`), then `__pc = STATE_LOOP_COND; continue`

### How do labels inside the body become arms?

Each label creates a new state arm. Code before the label is in one
arm; code after the label is in the label's arm.

### Expected output:

```
fn f():
    var x: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                setup()
                // for init
                (x = 0)
                __pc = 10   // STATE_LOOP_COND
                continue

            10 =>  // STATE_LOOP_COND
                (__goto_pending = 0)
                if x < 10:
                    // loop body (pre-label code)
                    work(x)
                    // goto SKIP
                    __pc = 1  // STATE_SKIP
                    continue
                else:
                    __pc = 11  // STATE_AFTER_LOOP
                    continue

            1 =>  // SKIP
                (__goto_pending = 0)
                finish(x)
                // for inc + loop back
                (x = x + 1)
                __pc = 10  // STATE_LOOP_COND
                continue

            11 =>  // STATE_AFTER_LOOP
                (__goto_pending = 0)
                cleanup()

            _ => break
    }
```

### Special case: for(;;) — infinite loop, no init/cond/inc

This is the match_() pattern. No init, cond is always true, no inc.
Simplifies to:

- `STATE_LOOP_TOP`: contains the first statement of the loop body
  (typically reading the opcode). No condition check needed.
- Labels inside the body become state arms.
- "break from switch" → `__pc = STATE_LOOP_TOP; continue` (loop
  back to re-read opcode).
- There is no "break from for(;;)" in match_() — exit is always
  via `return` or `goto` to a top-level label.

---

## while(cond) { body-with-labels }

### Example C:

```c
void f() {
    while (x > 0) {
        a();
        TARGET:
        b();
        x--;
    }
}
```

### Expected output:

```
fn f():
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>  // ENTRY + LOOP_COND
                (__goto_pending = 0)
                if x > 0:
                    a()
                    // fall through to TARGET
                    __pc = 1  // TARGET
                    continue
                // while condition false → exit

            1 =>  // TARGET
                (__goto_pending = 0)
                b()
                (x = x - 1)
                // loop back: check condition
                if x > 0:
                    a()
                    __pc = 1  // TARGET
                    continue
                // condition false → exit

            _ => break
    }
```

**Problem**: Duplicating the loop condition + pre-label body in
both the entry arm and the label arm is wasteful. Alternative:
create a synthetic LOOP_COND state.

### Better output with synthetic state:

```
fn f():
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                __pc = 10  // LOOP_COND
                continue

            10 =>  // LOOP_COND (synthetic)
                (__goto_pending = 0)
                if not (x > 0):
                    __pc = 11  // AFTER_LOOP
                    continue
                a()
                __pc = 1  // TARGET
                continue

            1 =>  // TARGET
                (__goto_pending = 0)
                b()
                (x = x - 1)
                __pc = 10  // LOOP_COND
                continue

            11 =>  // AFTER_LOOP
                (__goto_pending = 0)
                // continue with post-loop code

            _ => break
    }
```

### How does "break" translate?

`break` → `__pc = STATE_AFTER_LOOP; continue`

### How does "continue" translate?

`continue` → `__pc = STATE_LOOP_COND; continue`

---

## do { body-with-labels } while(cond)

### Example C:

```c
void f() {
    do {
        a();
        MIDDLE:
        b();
    } while (--x > 0);
}
```

### Expected output:

```
fn f():
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                __pc = 10  // LOOP_BODY_START
                continue

            10 =>  // LOOP_BODY_START (synthetic)
                (__goto_pending = 0)
                a()
                __pc = 1  // MIDDLE
                continue

            1 =>  // MIDDLE
                (__goto_pending = 0)
                b()
                // do-while condition
                (x = x - 1)
                if x > 0:
                    __pc = 10  // LOOP_BODY_START
                    continue
                // condition false → fall through to after loop

            _ => break
    }
```

### How does "break" translate?

`break` → `__pc = STATE_AFTER_LOOP; continue`

### How does "continue" translate?

`continue` → jump to condition check. For do-while, the condition
is at the bottom, so: `__pc = STATE_LOOP_COND; continue` where
STATE_LOOP_COND is a synthetic state that evaluates the condition
and either loops back or falls through.

---

## switch(expr) { case X: body-with-labels }

### Example C:

```c
void f() {
    switch (op) {
        case 1:
            a();
            goto COMMON;
        case 2:
            b();
            COMMON:
            c();
            break;
        default:
            d();
    }
}
```

### Where do labels inside case bodies become arms?

The label COMMON becomes a state arm. The code in case 2 before
COMMON stays in the switch arm for case 2. The code after COMMON
(including COMMON's own body) goes into the label's state arm.

### How does fallthrough behave?

The migrator currently handles fallthrough via case duplication
(duplicating the case body into the fallthrough target). When labels
are involved, fallthrough that crosses a label boundary becomes a
state transition: `__pc = STATE_COMMON; continue`.

### How does "break" from the switch translate?

`break` from switch → continue to the next statement after the
switch in the parent arm. If the switch is inside a for(;;) that's
being flattened, `break` from the switch means "loop back":
`__pc = STATE_LOOP_TOP; continue`.

### Expected output:

```
fn f():
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                match op:
                    1 =>
                        a()
                        // goto COMMON
                        __pc = 1  // COMMON
                        __goto_pending = 1
                    2 =>
                        b()
                        // fall through to COMMON
                        __pc = 1  // COMMON
                        __goto_pending = 1
                    _ =>
                        d()
                if __goto_pending != 0:
                    continue
                // after switch (reached by break)

            1 =>  // COMMON
                (__goto_pending = 0)
                c()
                // break from switch → after switch
                // (in this example, end of function)

            _ => break
    }
```

### The match_() switch(Fop) pattern

In match_(), the switch(Fop) is inside for(;;). The switch has
~308 case labels. Most case bodies end with `break` (break from
switch, which loops back in for(;;)). Some end with `continue`
(explicit for-loop continue). Some end with `goto` to a named
label or `RRETURN`.

In the flattened model:
- `STATE_LOOP_TOP` reads Fop and enters `match Fop:`
- Case bodies without labels or gotos-to-nested-labels stay inline
- Case bodies with `goto REPEATCHAR` etc. end with
  `__pc = STATE_REPEATCHAR; continue`
- Case bodies that fall through to a label end with
  `__pc = STATE_<label>; continue`
- `break` from any case → `__pc = STATE_LOOP_TOP; continue`

The RMATCH pattern inside case bodies:
```
match Fop:
    OP_STAR =>
        // ... setup ...
        // RMATCH(Fecode, RM25) expands to:
        (start_ecode = Fecode)
        (Freturn_id = 25)
        __pc = STATE_MATCH_RECURSE
        __goto_pending = 1
        // L_RM25 label → separate state arm
```

The L_RM25 resume state contains the code after the RMATCH call:
```
STATE_L_RM25 =>
    // code following RMATCH in the case body
    if rrc != MATCH_NOMATCH:
        __pc = STATE_RETURN_SWITCH  // RRETURN(rrc)
        continue
    // ... continue matching ...
    __pc = STATE_LOOP_TOP  // break from switch
    continue
```

### The RETURN_SWITCH dispatch

```
STATE_RETURN_SWITCH =>
    // frame backtrack logic
    match Freturn_id:
        1 => __pc = STATE_L_RM1; continue
        2 => __pc = STATE_L_RM2; continue
        ...
        39 => __pc = STATE_L_RM39; continue
        _ => return -44
```

This is the only place that transitions to L_RM states. It's a
pure dispatch table.

---

## if(cond) { body-with-labels } else { body-with-labels }

### Example C:

```c
void f() {
    if (x > 0) {
        a();
        TARGET:
        b();
    } else {
        c();
    }
    d();
}
```

### How do branches contribute arms?

The label TARGET inside the then-branch becomes a state arm. Code
before the label stays in the if-then arm. Code after the label
goes into the label's arm.

### Expected output:

```
fn f():
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                if x > 0:
                    a()
                    // fall through to TARGET
                    __pc = 1  // TARGET
                    continue
                else:
                    c()
                if __goto_pending != 0:
                    continue
                d()

            1 =>  // TARGET
                (__goto_pending = 0)
                b()
                // end of if-then, continue to post-if code
                d()

            _ => break
    }
```

**Note**: `d()` is duplicated. This is a consequence of lifting
the label out of the if-block. The alternative is to create a
synthetic "after-if" state:

```
            0 =>
                if x > 0:
                    a()
                    __pc = 1; continue  // TARGET
                else:
                    c()
                __pc = 10; continue  // AFTER_IF

            1 =>  // TARGET
                b()
                __pc = 10; continue  // AFTER_IF

            10 =>  // AFTER_IF (synthetic)
                d()
```

This avoids code duplication at the cost of more states.

---

## { body-with-labels } (compound block)

### Recursive lift

Compound blocks are transparent: descend into children, lifting any
labels found. No synthetic states needed for the block itself.

---

## goto <label> where <label> is nested

### How does this encode?

Exactly the same as any other goto:
```
__pc = STATE_<label>
__goto_pending = 1
break  // or continue, depending on nesting
```

The `__goto_pending` mechanism propagates the break out of any
enclosing loops/switches until it reaches the `while true { match __pc`
dispatch, where `continue` fires and dispatches to the new state.

When `__goto_pending = 1`, every enclosing loop in the generated
code has a guard:
```
if __goto_pending != 0:
    break  // propagate up
```

This mechanism already exists and works correctly. The only thing
missing is the state arm for the target label.

### Do we need anything beyond `__pc = N; __goto_pending = 1; break`?

No. The existing mechanism is sufficient. The fix is entirely about
creating the missing state arms, not about changing how gotos are
encoded.

---

# ARTIFACT 3: Test Cases

## Test 1: Top-level labels only (regression check)

### C source:

```c
int top_level_only(int x) {
    if (x > 10) goto DONE;
    x = x * 2;
    DONE:
    return x;
}
```

### Expected With output:

```
fn top_level_only(x_arg: c_int) -> c_int:
    var x: c_int = x_arg
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                if x > 10:
                    __pc = 1
                    __goto_pending = 1
                    continue
                if __goto_pending != 0:
                    continue
                (x = x * 2)
                __pc = 1
                continue

            1 =>  // DONE
                (__goto_pending = 0)
                return x

            _ => break
    }
    return 0
```

**This should be UNCHANGED from current behavior.** Validates no
regression.

---

## Test 2: One label inside a for-loop

### C source:

```c
int one_label_in_for(int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        if (i == 5) goto SKIP;
        sum += i;
        SKIP:
        sum += 1;
    }
    return sum;
}
```

### Expected With output:

```
fn one_label_in_for(n: c_int) -> c_int:
    var sum: c_int = 0
    var i: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (i = 0)
                __pc = 10
                continue

            10 =>  // FOR_COND (synthetic)
                (__goto_pending = 0)
                if not (i < n):
                    __pc = 11
                    continue
                if i == 5:
                    __pc = 1
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                (sum = sum + i)
                __pc = 1
                continue

            1 =>  // SKIP
                (__goto_pending = 0)
                (sum = sum + 1)
                // for inc + loop back
                (i = i + 1)
                __pc = 10
                continue

            11 =>  // AFTER_FOR (synthetic)
                (__goto_pending = 0)
                return sum

            _ => break
    }
    return 0
```

---

## Test 3: Multiple labels inside a for-loop

### C source:

```c
int multi_label_for(int n) {
    int result = 0;
    for (int i = 0; i < n; i++) {
        if (i % 3 == 0) goto THIRD;
        if (i % 2 == 0) goto EVEN;
        result += i;
        goto NEXT;
        EVEN:
        result += i * 2;
        goto NEXT;
        THIRD:
        result += i * 3;
        NEXT:
        result += 1;
    }
    return result;
}
```

### Expected With output:

```
fn multi_label_for(n: c_int) -> c_int:
    var result: c_int = 0
    var i: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (i = 0)
                __pc = 10
                continue

            10 =>  // FOR_COND
                (__goto_pending = 0)
                if not (i < n):
                    __pc = 11
                    continue
                if i % 3 == 0:
                    __pc = 2     // THIRD
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                if i % 2 == 0:
                    __pc = 1     // EVEN
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                (result = result + i)
                __pc = 3         // NEXT
                continue

            1 =>  // EVEN
                (__goto_pending = 0)
                (result = result + i * 2)
                __pc = 3         // NEXT
                continue

            2 =>  // THIRD
                (__goto_pending = 0)
                (result = result + i * 3)
                __pc = 3         // NEXT
                continue

            3 =>  // NEXT
                (__goto_pending = 0)
                (result = result + 1)
                (i = i + 1)
                __pc = 10        // FOR_COND
                continue

            11 =>  // AFTER_FOR
                (__goto_pending = 0)
                return result

            _ => break
    }
    return 0
```

---

## Test 4: Labels inside a switch inside a for-loop (match_() pattern)

### C source:

```c
int switch_for_labels(const unsigned char *code, int len) {
    int result = 0;
    int op;
    int i;

    for (;;) {
        op = *code++;
        switch (op) {
            case 1:  /* OP_ADD */
                result += *code++;
                break;

            case 2:  /* OP_MUL_SETUP */
            case 3:  /* OP_MUL_SETUP2 */
                i = *code++;
                goto DO_MUL;

            case 4:  /* OP_MUL_DIRECT */
                i = 1;
                DO_MUL:
                result *= i;
                break;

            case 0:  /* OP_END */
                return result;

            default:
                return -1;
        }
    }
}
```

### Expected With output:

```
fn switch_for_labels(code_arg: *const u8, len: c_int) -> c_int:
    var result: c_int = 0
    var op: c_int = 0
    var i: c_int = 0
    var code: *const u8 = code_arg
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                __pc = 10
                continue

            10 =>  // LOOP_TOP (for(;;) entry)
                (__goto_pending = 0)
                (op = (unsafe: *code) as c_int)
                (code = code + 1)
                match op:
                    1 =>
                        (result = result + (unsafe: *code) as c_int)
                        (code = code + 1)
                        // break from switch → loop back
                    2 | 3 =>
                        (i = (unsafe: *code) as c_int)
                        (code = code + 1)
                        // goto DO_MUL
                        __pc = 1  // DO_MUL
                        __goto_pending = 1
                    4 =>
                        (i = 1)
                        // fall through to DO_MUL
                        __pc = 1  // DO_MUL
                        __goto_pending = 1
                    0 =>
                        return result
                    _ =>
                        return -1
                if __goto_pending != 0:
                    continue
                // break from switch → loop back
                __pc = 10
                continue

            1 =>  // DO_MUL
                (__goto_pending = 0)
                (result = result * i)
                // break from switch → loop back
                __pc = 10
                continue

            _ => break
    }
    return 0
```

---

## Test 5: Goto from nested label to top-level label

### C source:

```c
int nested_to_toplevel(int x) {
    for (;;) {
        if (x > 100) goto DONE;
        DOUBLE:
        x = x * 2;
        if (x > 50) goto DONE;
    }
    DONE:
    return x;
}
```

### Expected With output:

```
fn nested_to_toplevel(x_arg: c_int) -> c_int:
    var x: c_int = x_arg
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                __pc = 10
                continue

            10 =>  // LOOP_TOP
                (__goto_pending = 0)
                if x > 100:
                    __pc = 2  // DONE
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                __pc = 1  // DOUBLE (fall through)
                continue

            1 =>  // DOUBLE
                (__goto_pending = 0)
                (x = x * 2)
                if x > 50:
                    __pc = 2  // DONE
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                // loop back
                __pc = 10
                continue

            2 =>  // DONE
                (__goto_pending = 0)
                return x

            _ => break
    }
    return 0
```

---

## Test 6: Goto from top-level to nested label

### C source:

```c
int toplevel_to_nested(int x) {
    if (x < 0) goto NEGATIVE;
    for (;;) {
        x--;
        NEGATIVE:
        x = -x;
        if (x == 0) break;
    }
    return x;
}
```

### Expected With output:

```
fn toplevel_to_nested(x_arg: c_int) -> c_int:
    var x: c_int = x_arg
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                if x < 0:
                    __pc = 1  // NEGATIVE
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                __pc = 10  // LOOP_TOP
                continue

            10 =>  // LOOP_TOP
                (__goto_pending = 0)
                (x = x - 1)
                __pc = 1  // NEGATIVE (fall through)
                continue

            1 =>  // NEGATIVE
                (__goto_pending = 0)
                (x = 0 - x)
                if x == 0:
                    __pc = 11  // AFTER_LOOP
                    continue
                // loop back
                __pc = 10
                continue

            11 =>  // AFTER_LOOP
                (__goto_pending = 0)
                return x

            _ => break
    }
    return 0
```

---

## Test 7: Nested loops with labels

### C source:

```c
int nested_loops(int n) {
    int total = 0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            if (i == j) goto SKIP_INNER;
            total += i * j;
            SKIP_INNER:
            total += 1;
        }
        AFTER_INNER:
        total += 100;
    }
    return total;
}
```

### Expected With output:

```
fn nested_loops(n: c_int) -> c_int:
    var total: c_int = 0
    var i: c_int = 0
    var j: c_int = 0
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                (i = 0)
                __pc = 10
                continue

            10 =>  // OUTER_FOR_COND
                (__goto_pending = 0)
                if not (i < n):
                    __pc = 11
                    continue
                (j = 0)
                __pc = 20
                continue

            20 =>  // INNER_FOR_COND
                (__goto_pending = 0)
                if not (j < n):
                    __pc = 2  // AFTER_INNER
                    continue
                if i == j:
                    __pc = 1  // SKIP_INNER
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                (total = total + i * j)
                __pc = 1
                continue

            1 =>  // SKIP_INNER
                (__goto_pending = 0)
                (total = total + 1)
                (j = j + 1)
                __pc = 20  // INNER_FOR_COND
                continue

            2 =>  // AFTER_INNER
                (__goto_pending = 0)
                (total = total + 100)
                (i = i + 1)
                __pc = 10  // OUTER_FOR_COND
                continue

            11 =>  // AFTER_OUTER_FOR
                (__goto_pending = 0)
                return total

            _ => break
    }
    return 0
```

---

## Test 8: Switch fallthrough + labels

### C source:

```c
int switch_fallthrough(int op, int x) {
    switch (op) {
        case 1:
            x += 10;
            /* fallthrough */
        case 2:
            x += 20;
            goto DONE;
        case 3:
            x += 30;
            DONE:
            x += 1;
            break;
        default:
            x = -1;
    }
    return x;
}
```

### Expected With output:

The migrator already handles fallthrough by duplicating case bodies
or merging. With labels involved, the fallthrough into DONE becomes
a state transition.

```
fn switch_fallthrough(op: c_int, x_arg: c_int) -> c_int:
    var x: c_int = x_arg
    var __pc: i32 = 0
    var __goto_pending: i32 = 0
    while true {
        match __pc:
            0 =>
                (__goto_pending = 0)
                match op:
                    1 =>
                        (x = x + 10)
                        (x = x + 20)     // fallthrough from case 1 into case 2
                        __pc = 1          // goto DONE
                        __goto_pending = 1
                    2 =>
                        (x = x + 20)
                        __pc = 1          // goto DONE
                        __goto_pending = 1
                    3 =>
                        (x = x + 30)
                        __pc = 1          // fall through to DONE
                        __goto_pending = 1
                    _ =>
                        (x = -1)
                if __goto_pending != 0:
                    continue
                return x

            1 =>  // DONE
                (__goto_pending = 0)
                (x = x + 1)
                // break from switch → return x
                return x

            _ => break
    }
    return 0
```

---

## Summary

The test cases cover:
1. **Regression** — top-level labels (no change expected)
2. **Basic** — one label in a for-loop
3. **Multiple** — several labels in a for-loop
4. **Complex** — labels inside switch inside for-loop (match_() pattern)
5. **Cross-level goto** — nested label → top-level label
6. **Cross-level goto** — top-level → nested label
7. **Nested loops** — labels at different loop depths
8. **Fallthrough** — switch fallthrough interacting with labels

These should be written as C files that the migrator can process,
with the expected output verified by `with check` + runtime.

---

## Test 9: Macro-expanded labels (RMATCH pattern)

### Concern

`match_()` has ~68 L_RM labels created by the RMATCH macro. These
labels don't appear in the visible C source — they only exist
after preprocessing. The fix must handle them. Specifically:
`ci_subtree_has_labels` must see macro-expanded labels.

### Confirmation

`ci_subtree_has_labels` will use the same `with_ci_cursor_kind` /
`with_ci_num_children` / `with_ci_child` APIs as
`ci_collect_labels_rec`. These APIs operate on the fully
preprocessed libclang AST. Macros are already expanded. Every
`L_RM##N` label is a plain `LabelStmt` node in the AST.

Evidence: `ci_collect_labels_rec` already finds all L_RM labels
(RETURN_SWITCH gets state 88, meaning 88 labels were counted).

### C source:

```c
/* Simulates the RMATCH/RRETURN/LBL pattern from pcre2_match.c */

#define CALL(ra, rb) \
    do { save = ra; ret_id = rb; goto DISPATCH; L##rb:; } while(0)

#define RET(ra) \
    do { result = ra; goto RETURN_POINT; } while(0)

#define DEST(val) case val: goto L##val;

int rmatch_pattern(int mode) {
    int save = 0;
    int ret_id = 0;
    int result = 0;
    int depth = 0;

    for (;;) {
        switch (mode) {
            case 1:
                CALL(10, 1);
                if (result != 0) RET(result);
                CALL(20, 2);
                if (result != 0) RET(result);
                RET(-1);

            case 2:
                CALL(30, 3);
                RET(result + 1);

            default:
                RET(save);
        }
    }

DISPATCH:
    depth++;
    if (depth > 5) return -99;
    mode = save;
    goto L0;  /* re-enter the for(;;) loop */

L0: ;  /* synthetic label at for(;;) top */

RETURN_POINT:
    depth--;
    if (depth == 0) return result;
    switch (ret_id) {
        DEST(1)
        DEST(2)
        DEST(3)
        default: return -44;
    }
}
```

### After preprocessing, the compiler sees:

```c
int rmatch_pattern(int mode) {
    int save = 0;
    int ret_id = 0;
    int result = 0;
    int depth = 0;

    for (;;) {
        switch (mode) {
            case 1:
                do { save = 10; ret_id = 1; goto DISPATCH; L1:; } while(0);
                if (result != 0) do { result = result; goto RETURN_POINT; } while(0);
                do { save = 20; ret_id = 2; goto DISPATCH; L2:; } while(0);
                if (result != 0) do { result = result; goto RETURN_POINT; } while(0);
                do { result = -1; goto RETURN_POINT; } while(0);

            case 2:
                do { save = 30; ret_id = 3; goto DISPATCH; L3:; } while(0);
                do { result = result + 1; goto RETURN_POINT; } while(0);

            default:
                do { result = save; goto RETURN_POINT; } while(0);
        }
    }

DISPATCH:
    depth++;
    if (depth > 5) return -99;
    mode = save;
    goto L0;

L0: ;

RETURN_POINT:
    depth--;
    if (depth == 0) return result;
    switch (ret_id) {
        case 1: goto L1;
        case 2: goto L2;
        case 3: goto L3;
        default: return -44;
    }
}
```

### Labels visible to the migrator (post-expansion):

| Label | Location | State ID |
|-------|----------|----------|
| DISPATCH | top-level | 1 |
| L0 | top-level | 2 |
| RETURN_POINT | top-level | 3 |
| L1 | nested: for(;;) → switch → case 1 → do-while body | 4 |
| L2 | nested: for(;;) → switch → case 1 → do-while body | 5 |
| L3 | nested: for(;;) → switch → case 2 → do-while body | 6 |

### Expected With output:

```
fn rmatch_pattern(mode_arg: c_int) -> c_int:
    var save: c_int = 0
    var ret_id: c_int = 0
    var result: c_int = 0
    var depth: c_int = 0
    var mode: c_int = mode_arg
    var __pc: i32 = 0
    var __goto_pending: i32 = 0

    while true {
        match __pc:

            0 =>  // ENTRY → for(;;) loop top
                (__goto_pending = 0)
                __pc = 10
                continue

            10 =>  // LOOP_TOP (synthetic, for(;;) entry)
                (__goto_pending = 0)
                match mode:
                    1 =>
                        // CALL(10, 1): do { save=10; ret_id=1; goto DISPATCH; L1:; } while(0)
                        (save = 10)
                        (ret_id = 1)
                        __pc = 1  // DISPATCH
                        __goto_pending = 1
                        // L1 label → separate state arm (state 4)
                    2 =>
                        // CALL(30, 3): similar
                        (save = 30)
                        (ret_id = 3)
                        __pc = 1  // DISPATCH
                        __goto_pending = 1
                    _ =>
                        // RET(save)
                        (result = save)
                        __pc = 3  // RETURN_POINT
                        __goto_pending = 1
                if __goto_pending != 0:
                    continue
                // break from switch → loop back
                __pc = 10
                continue

            4 =>  // L1 (resume after CALL RM1)
                (__goto_pending = 0)
                if result != 0:
                    (result = result)
                    __pc = 3  // RETURN_POINT (RET)
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                // CALL(20, 2)
                (save = 20)
                (ret_id = 2)
                __pc = 1  // DISPATCH
                __goto_pending = 1
                continue
                // L2 → state 5

            5 =>  // L2 (resume after CALL RM2)
                (__goto_pending = 0)
                if result != 0:
                    (result = result)
                    __pc = 3  // RETURN_POINT
                    __goto_pending = 1
                if __goto_pending != 0:
                    continue
                // RET(-1)
                (result = -1)
                __pc = 3  // RETURN_POINT
                continue

            6 =>  // L3 (resume after CALL RM3)
                (__goto_pending = 0)
                // RET(result + 1)
                (result = result + 1)
                __pc = 3  // RETURN_POINT
                continue

            1 =>  // DISPATCH
                (__goto_pending = 0)
                (depth = depth + 1)
                if depth > 5:
                    return -99
                (mode = save)
                __pc = 2  // L0 (goto L0 → re-enter for(;;))
                continue

            2 =>  // L0 (at for(;;) top)
                (__goto_pending = 0)
                __pc = 10  // LOOP_TOP
                continue

            3 =>  // RETURN_POINT
                (__goto_pending = 0)
                (depth = depth - 1)
                if depth == 0:
                    return result
                // switch(ret_id) dispatch
                match ret_id:
                    1 => __pc = 4; continue  // L1
                    2 => __pc = 5; continue  // L2
                    3 => __pc = 6; continue  // L3
                    _ => return -44

            _ => break
    }
    return 0
```

### What this test exercises:

1. **Macro-expanded labels (L1, L2, L3)** — only visible after
   preprocessing, inside do-while(0) blocks inside switch cases
   inside a for(;;). Exercises `ci_subtree_has_labels` on
   post-expansion AST.

2. **The RMATCH/RRETURN dispatch pattern** — a top-level label
   (RETURN_POINT) that dispatches via switch(ret_id) to L_RM
   labels nested deep inside the for(;;)/switch structure.

3. **BUG A interaction** — the LabelStmt-with-NullStmt-body inside
   do-while(0) must NOT abort the containing CompoundStmt translation.

4. **Split case bodies** — a single case body (case 1) contains
   multiple CALL/RET sequences separated by L_RM labels. Each label
   must become its own state arm. The code between labels must be
   correctly split across arms.

---

# ARTIFACT 5: Why Exactly 4 Arms Survive

## The precise mechanism

The walk in `ci_lower_goto_body_structural` (line 9860) iterates
direct children of the function body's CompoundStmt. A child gets
its own state arm **only** if it is a `CXK_LABEL_STMT`. All other
children are processed by `ci_lower_stmt_goto_ir` and appended to
the current arm's statement list.

## The 4 surviving arms

### Arm 0 (state 0): Entry

Not created by a label. This is the implicit entry arm, initialized
at line 9852 (`cur_state = 0`). It collects all statements from the
start of the function body until the first LabelStmt. For `match_()`,
this includes:
- Variable declarations (hoisted separately)
- Assignment statements (initializing locals)
- `goto NEW_FRAME` → translated to `__pc = 2; __goto_pending = 1`

The arm is flushed when the first LabelStmt (MATCH_RECURSE) is
encountered (line 9868-9879).

### Arm 1 (state 1): MATCH_RECURSE

Created at line 9864-9883 when the walk encounters the LabelStmt
for MATCH_RECURSE. This label is a **direct child** of the function
body's CompoundStmt because in the C source:

```c
// line 748: goto NEW_FRAME;
// line 753: MATCH_RECURSE:
//             N = (heapframe *)...;  ← label's single child
// line 760: if ((heapframe *)... >= frames_top) {  ← sibling
```

The LabelStmt's single child (the assignment `N = ...`) is processed
at line 9895. The remaining statements (the if-block, frame copying,
etc.) are siblings in the CompoundStmt, processed in subsequent
iterations of the walk and appended to arm 1's children.

Arm 1 is flushed when the next LabelStmt (NEW_FRAME) is encountered.

### Arm 2 (state 2): NEW_FRAME

Created when the walk encounters the LabelStmt for NEW_FRAME. Same
pattern as MATCH_RECURSE: the label is a direct child of the function
body. Its single child (the next statement) is processed. Siblings
are appended to arm 2's children, including:
- Frame setup code
- The entire `for(;;) { switch(Fop) { ... } }` opcode dispatch loop,
  processed as a single ForStmt by `ci_lower_stmt_goto_ir` → becomes
  a `while true { match Fop: ... }` block
- `PCRE2_DEBUG_UNREACHABLE()` call

The for(;;) is processed as **one opaque subtree**. All 85 labels
inside it (17 named + 68 L_RM) are found by `ci_collect_labels` and
get state IDs, but `ci_lower_stmt_goto_ir` treats labels as
transparent wrappers (line 7842-7846: just recurse into the child,
discard the label). No state arms are created for them.

Arm 2 is flushed when the next LabelStmt (RETURN_SWITCH) is
encountered.

### Arm 88 (state 88): RETURN_SWITCH

Created when the walk encounters the LabelStmt for RETURN_SWITCH.
This label is at line 6909 in the C source, **after** the for(;;)
loop closes at line 6897, making it a direct child of the function
body CompoundStmt. Its single child (the if-stmt for last_used_ptr)
is processed. Siblings include:
- `if (Frdepth == 0) return rrc;`
- `F = backtrack;`
- `callout_flags |= ...;`
- `switch (Freturn_id) { ... }` ← **SILENTLY DROPPED**

The switch(Freturn_id) dispatch is silently dropped because it fails
to translate. See "Bug A" below.

Arm 88 is the final arm, flushed at line 9930-9939 after the walk
ends.

## The 84 missing arms (states 3-87)

All 84 missing labels share two structural properties:

1. **Not direct children of the function body CompoundStmt.** They
   are nested inside the ForStmt (for(;;) at line 881), which is
   itself a direct child. The walk at line 9860 processes the ForStmt
   via the "else" branch (line 9921-9922), which calls
   `ci_lower_stmt_goto_ir`. This function processes the ForStmt as
   one unit, recursing into the switch, cases, do-while blocks, etc.
   When it encounters a LabelStmt (line 7842-7846), it just processes
   the label's child and discards the label. No arm is created.

2. **State IDs assigned by `ci_collect_labels_rec` (line 9731)**
   which walks ALL descendants recursively. These IDs are used in
   goto translations (`__pc = N; __goto_pending = 1`) but have no
   corresponding arms in the `match __pc:` dispatch.

The 84 labels break down as:
- **17 named labels** (REPEATCHAR, REPEATNOTCHAR, REPEATTYPE,
  REF_REPEAT, POSSESSIVE_NON_CAPTURE, POSSESSIVE_CAPTURE,
  POSSESSIVE_GROUP, GROUPLOOP, ASSERT_NOT_FAILED, SCS_OFFSET_FOUND,
  ASSERT_NL_OR_EOS, ENDLOOP00-03, ENDLOOP99, GOT_MAX) — all inside
  switch(Fop) case bodies within the for(;;)
- **~67 L_RM labels** — inside do{...}while(0) blocks within
  switch(Fop) case bodies, created by RMATCH macro expansion

## Bug A: The silent drop cascade

During investigation, a second bug was discovered that compounds
the nested-label problem.

**Root cause:** In `ci_lower_stmt_goto_ir`, when processing a
CompoundStmt (line 7848-7868), if any child returns `CiStmtId(0)`
AND the child's kind is not `CXK_NULL_STMT`, the entire
CompoundStmt translation aborts (returns 0).

A LabelStmt whose body is a NullStmt (like `L_RM25:;`) triggers
this: the label handler (line 7842-7846) recurses into the NullStmt
child, which returns 0. Back in the CompoundStmt handler, the child
is a LabelStmt (not a NullStmt), so the 0 result triggers an abort.

**Cascade chain:**
```
LabelStmt(L_RM25) → body is NullStmt → returns 0
  ↓
CompoundStmt (do-while body) → child LabelStmt returned 0 → aborts (returns 0)
  ↓
DoStmt → body failed → aborts (returns 0)
  ↓
CompoundStmt (case body) → child DoStmt returned 0 → aborts (returns 0)
  ↓
Switch case body → aborts (returns 0)
```

**Two different consequences depending on the switch path:**

1. **No-fallthrough path** (line 7700): If ANY case body returns 0,
   the entire switch returns 0. This is why the `switch(Freturn_id)`
   dispatch in RETURN_SWITCH is silently dropped — its L_RM goto
   targets are valid, but some case bodies in the *main* switch fail.
   Wait — actually the dispatch switch has no L_RM labels in its
   cases, only `goto L_RMN` statements. The case bodies are just
   gotos, which translate fine. So the dispatch switch should
   succeed... unless the `default:` case fails.

   The default case is: `do{}while(0); return PCRE2_ERROR_INTERNAL;`
   The do-while(0) is a no-op. In the preprocessed AST, this is a
   DoStmt with empty CompoundStmt body and condition 0. The return
   is a sibling of the DoStmt inside the DefaultStmt.

   Actually: `default: PCRE2_DEBUG_UNREACHABLE(); return -44;`
   `PCRE2_DEBUG_UNREACHABLE()` expands to `do {} while(0)`.
   In non-debug: empty body. DefaultStmt child = DoStmt.
   After DoStmt, ReturnStmt is a sibling.

   `ci_lower_stmt_strip_break_goto_ir` calls `ci_lower_stmt_goto_ir`
   on the DefaultStmt's child. DefaultStmt has child 0 = DoStmt(body=
   CompoundStmt(empty), cond=0). `ci_lower_stmt_goto_ir` for DoStmt
   (line 7957): `body_id = ci_lower_stmt_goto_ir(body)`. Body is
   empty CompoundStmt → returns 0. `if (body_id as i32) == 0:
   return 0`. The DoStmt returns 0. So the DefaultStmt's body fails.
   `ci_lower_switch_body_goto_ir` at line 7722-7724: `default_body_id
   = ci_lower_stmt_strip_break_goto_ir(...)`, `if (default_body_id
   as i32) == 0: return 0 as CiStmtId`. **The empty do-while(0)
   default case aborts the entire switch!**

2. **Fallthrough path** (line 7730): Failed case bodies are silently
   skipped. This is why the main switch(Fop) survives — case bodies
   with RMATCH (containing L_RM labels) fail, but the switch as a
   whole succeeds with those case bodies missing.

**Summary of Bug A's impact on match_():**

- The main `switch(Fop)` loses all case bodies that contain RMATCH
  calls (~72 cases). The generated match expression has only the
  non-RMATCH cases.
- The `switch(Freturn_id)` dispatch is completely dropped because
  its `default:` case contains `do{}while(0)` which fails to
  translate.
- Both failures are silent — no error, no warning.

**Fix for Bug A:** In `ci_lower_stmt_goto_ir`:
1. The CompoundStmt handler (line 7862) should treat LabelStmt
   the same as NullStmt when its child returns 0. A label wrapping
   a null statement (`L_RM25:;`) is semantically a no-op and should
   not abort the containing block. Change the check:
   `if (child_id as i32) == 0 and kind != CXK_NULL_STMT:`
   to also exclude `CXK_LABEL_STMT`:
   `if (child_id as i32) == 0 and kind != CXK_NULL_STMT and kind != CXK_LABEL_STMT:`
2. The DoStmt handler (line 7960-7962) should treat an empty
   do-while(0) body as a no-op rather than aborting. When
   `body_id == 0` and the condition is a constant 0 (do-while(0)),
   return a no-op instead of 0.

Bug A must be fixed alongside Bug B (the missing state arms).
Without Bug A fixed, even if state arms are created for nested
labels, the case bodies containing L_RM labels would still be
silently dropped, producing incorrect code.

## Edge cases to verify

**Q: Can a top-level label get missed?**

No. The walk iterates ALL direct children. Every LabelStmt that is
a direct child of the CompoundStmt creates a new arm. There is no
filtering or condition that could skip a top-level label. The only
way a top-level label could be missed is if it's not a direct child
— which by definition makes it not top-level.

**Q: Could there be 5 top-level labels instead of 3?**

No, for `match_()` specifically. MATCH_RECURSE (753), NEW_FRAME
(849), and RETURN_SWITCH (6909) are the only LabelStmts that are
direct children of the function body. FRAGMENT_RESTART and ENDLOOP
are in a different function (`pcre2_match_8`). All other labels are
nested inside the for(;;) loop.

**Q: Is there any accidental behavior keeping the 4 working?**

No. The mechanism is purely structural: direct-child LabelStmts
create arms, everything else doesn't. The fix must preserve this
for top-level labels while adding arm creation for nested labels.

**Q: Does the fix need to handle the case where a label is both
a direct child AND would be found by recursive descent?**

Yes, but trivially. `ci_collect_labels_rec` assigns state IDs to
ALL labels. `ci_lower_goto_body_structural` currently only creates
arms for direct-child labels. The fix adds arm creation for nested
labels. Direct-child labels continue to work as before. There is no
double-counting because each label has exactly one state ID and
each state ID gets exactly one arm.
