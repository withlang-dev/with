# 23. `with` Block Semantics

### 23.1 Plain Binding Desugaring

Section 7 owns the full `with` dispatch rule. This section specifies
only the desugaring of plain, non-guarded `with e as x` and
`with e as mut x` forms after full dispatch has selected the plain
binding path. It does not define guarded access, implicit context,
record update, or the global `with` dispatch order.

| Syntax | Desugaring |
|--------|------------|
| `with e as mut x: body` | `{ var x = e; body; x }` |
| `with e as x: body` | `{ let x = e; body }` |

The binding is scoped to the block and cannot escape. In the plain
binding path, `mut` selects a mutable local binding; without `mut`, the
binding is immutable. In the guarded path, `mut` is checked against the
selected guard protocol instead.

### 23.2 Multiple Bindings

Multiple bindings nest left-to-right:
`with a as x, b as mut y: body` desugars to nested scoped blocks.

Multiple bindings in the non-guarded (binding) forms follow the
same nesting: each binding is in scope for all subsequent bindings
and the body.

### 23.3 Non-Local Control Flow

All `with` forms are transparent for control flow. The following
observable behaviors are required:

- `return` inside a `with` block returns from the **enclosing function**.
- `break` inside a `with` block breaks the **enclosing loop**.
- `continue` inside a `with` block continues the **enclosing loop**.
- Labeled `break 'label` and `continue 'label` inside a `with` block
  may target visible labels in the enclosing function; `with` blocks
  do not hide labels.
- `goto 'label` inside a `with` block may target a visible label in
  the enclosing function, subject to the normal goto restrictions
  (§13.5b).
- `?` inside a `with` block propagates to the **enclosing function**.

The mechanism by which the compiler achieves this is unspecified.
Possible approaches include tagged-union returns, inlining the
`enter` call, or compiler-special-cased lowering.

---
