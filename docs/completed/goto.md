# §13.0 — Labels and labeled jumps

A label declares a target for jumps within a function.

## §13.0.1 — Syntax

```
label-statement ::= label statement
label           ::= "'" identifier
```

A label may precede any statement: a block, a loop, a `let`, a `return`, an expression statement, or another label. The label and the statement it precedes are syntactically a single statement; the label does not declare a new scope.

Within a function, every label name must be unique. The label namespace is shared across `goto`, `break`, and `continue`.

```with
fn example:
    'top
    var i = 0
    'loop while i < 10:
        if i == 5:
            break 'loop
        i = i + 1
    'done
    print("finished")
```

## §13.0.2 — Jump statements

Three labeled jump forms target labels:

| Statement     | Target restriction                                     |
| ------------- | ------------------------------------------------------ |
| `goto 'L`     | Any label in the same function, subject to §13.X.2     |
| `break 'L`    | A labeled loop or labeled block (§13.5b)               |
| `continue 'L` | A labeled loop only (§13.5b)                           |

Unlabeled `break` and `continue` also exist; they target the innermost enclosing loop and are specified in §13.5b.

The static restrictions on `goto` (function-local, no entry into block, no init-skip) are specified in §13.X.2. Labeled break and continue have their own scoping rules in §13.5b.

## §13.0.3 — Diagnostics

A label that is not targeted by `goto`, `break`, or `continue` produces an `unused-label` warning. This applies uniformly to all labels regardless of what statement they precede; labels exist to be targets, and an untargeted label is misleading. Code that wants to name a construct purely for readability should use a comment.

A labeled statement may be reachable only via goto. Ordinary unreachable-code diagnostics are suppressed for a labeled statement and for following statements until the next control-flow terminator or the next labeled statement.

---

# §13.5b — Labeled break and continue

`break 'L` exits the labeled loop or labeled block named `'L`. The label must be declared on a `while`, `for`, or block statement that lexically encloses the `break`.

`continue 'L` skips to the next iteration of the labeled loop named `'L`. The label must be declared on a `while` or `for` statement that lexically encloses the `continue`.

Unlabeled `break` and `continue` target the innermost enclosing loop. An unlabeled `break` inside a labeled block (not a loop) is an error; use the labeled form `break 'L`.

The label syntax and namespace are defined in §13.0.

```with
fn search(items: Vec[Item], targets: Vec[Item]) -> i32:
    var found = -1
    'outer for i in 0..items.len():
        for j in 0..targets.len():
            if items.get(i) == targets.get(j):
                found = i as i32
                break 'outer
    found
```

---

# §13.X — Goto statement

`goto` transfers control to a labeled statement within the same function.

## §13.X.1 — Syntax

```
goto-statement ::= "goto" label
```

A goto statement transfers control unconditionally to the labeled statement named by `label`. Label syntax and the shared label namespace are defined in §13.0.

Conditional gotos are written by composition with `if`:

```with
if cond: goto 'label
```

A function-level example:

```with
fn example:
    var i = 0
    'top
    if i >= 10:
        goto 'done
    process(i)
    i = i + 1
    goto 'top
    'done
    print("finished")
```

## §13.X.2 — Static restrictions

The compiler rejects, at parse or sema time, any `goto` that violates the following:

**Function-local.** The target label must be declared in the same function as the goto statement. Goto cannot cross function boundaries.

**No entry into a block from outside.** The target label's enclosing scope chain must be a prefix of the goto site's enclosing scope chain. Equivalently: traversing from the goto site to the target may only exit scopes, never enter them.

This excludes patterns such as jumping from one branch of an `if` into a labeled statement inside the other branch (the two branches are sibling scopes, neither a prefix of the other), jumping into a loop body from outside the loop, or jumping into a switch case from outside the switch.

**No skipping of variable initialization.** A goto must not jump over a variable declaration when that variable is in scope at the target. Formally: for every binding `x` declared at point P, every path from any goto target to a use of `x` must pass through P.

## §13.X.3 — Destruction order

When a goto exits one or more blocks, destructors for values owned by those blocks run in reverse order of declaration, identical to the destruction sequence for falling out of those blocks normally or for an equivalent labeled `break` (§13.5b).

Because the static restrictions forbid goto from entering a block from outside, the destruction sequence is fully determined by the lexical structure between the goto site and its target.

## §13.X.4 — Diagnostics

Violations of the static restrictions produce errors. The following are illustrative:

```
error: goto target is in a different function
  --> example.w:42:5
   |
42 |     goto 'other_fn_label
   |     ^^^^^^^^^^^^^^^^^^^^
   |
   = note: 'other_fn_label is declared in fn `other_fn` at example.w:30:1
   = help: goto can only target labels in the same function
```

```
error: goto would enter a block from outside
  --> example.w:42:9
   |
40 |     if cond:
41 |         do_setup()
42 |         goto 'inner
   |         ^^^^^^^^^^^
43 |     else:
44 |         'inner
   |         ------ label declared in sibling scope
   |
   = help: goto cannot enter a block from outside; consider restructuring
           with labeled break, or moving 'inner to a position both branches
           can reach
```

```
error: goto would skip variable initialization
  --> example.w:42:5
   |
42 |     goto 'use_x
   |     ^^^^^^^^^^^
43 |     let x = compute()
44 |     'use_x
45 |     print(x)
   |           - x is used here but goto skips its initialization at line 43
   |
   = help: declare and initialize x before the goto, or restructure the
           control flow
```

## §13.X.5 — Use in `with migrate`

`with migrate` emits goto when the C source contains control flow that cannot be expressed with structured constructs — specifically, when stackify analysis rejects the function's control-flow graph as irreducible.

For reducible C, the migrator emits structured With using `while`, `if`, labeled `break`, and labeled `continue`; goto does not appear. For irreducible C, the migrator emits a goto-based lowering: each basic block becomes a labeled statement at function scope, each control-flow edge becomes a goto or conditional goto.

The migrator emits the file-level attribute `#![migrator_generated]` on every file it produces. That attribute is informational; it does not affect compilation.

## §13.X.6 — Rationale

This section is informative.

With includes `goto` for the same reasons C and Go do: occasionally, control flow is simpler with an explicit jump than with structured constructs. The static restrictions ensure goto is well-defined with respect to scope and destruction order — it cannot leave bindings uninitialized, cannot enter blocks from outside, cannot cross function boundaries.

Idiomatic With rarely uses goto. The structured constructs — labeled `break`, labeled `continue`, `while`, `for`, `if`, `match` — handle nearly every case where goto would be considered. Goto exists for the cases they don't cover: state machines, cleanup chains in error-handling code, and mechanical translation from C source whose control flow does not reduce.

**Non-goals.** With does not support every form of C goto. Specifically:

- *Computed goto* (the gcc extension `goto *ptr;`) is not supported.
- *Goto across function boundaries* via `setjmp`/`longjmp` is not supported; functions using these are not migratable.
- *Cross-block entry* (jumping into a block from outside) is not supported, as specified in §13.X.2.

These restrictions are deliberate and unlikely to change. The migrator emits a diagnostic and exits non-zero for C functions that require unsupported patterns.

---

# §30 — Grammar appendix update

Add to the statement productions:

```
statement       ::= ... existing productions ...
                  | label-statement
                  | goto-statement

label-statement ::= label statement
goto-statement  ::= "goto" label
label           ::= "'" identifier
```

The `label` production is shared across goto, labeled break, and labeled continue (§13.0).

---

# §3 — Reserved keywords

Add `goto` to the reserved keyword list.
