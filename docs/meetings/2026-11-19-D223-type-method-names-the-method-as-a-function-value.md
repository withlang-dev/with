# D223 — `Type.method` names the method as a function value

**Laws:** 1 (the method's signature already states the receiver's mode;
the value's type adds nothing to write), D110 (a parameter's mode is what
the callee does with it), D218 (a function type states the mode).

**Date:** 2026-11-19. **Status:** ruled by Eric; the §9.3a words are his.

**Context.** D218's third point gave the unbound form of a `mut fn` the
type `fn(mut T) -> R`. Implementing it showed that no method was a value:
`Bag.make`, `Bag.peek` and `Bag.into_n` were "unknown field", and only the
`mut fn` case had a refusal of its own. The spec had no section.

**Decision.** `Type.method` is a function value. Each row is the method's
own signature with the receiver written first:

| Method | Type of `Bag.method` |
|---|---|
| no receiver, `fn Bag.make(v: i32) -> Bag` | `fn(i32) -> Bag` |
| `fn peek() -> i32` | `fn(&Bag) -> i32` |
| `mut fn bump() -> i32` | `fn(mut Bag) -> i32` |
| `move fn into_n() -> i32` | `fn(Bag) -> i32` |

- The bound form `x.method` without a call is refused in every mode: one
  rule, and it can be relaxed later without breaking anything.
- A method of a generic type is named through the instance
  (`List[i32].rest`); only a method with type parameters of its own, and
  the type named without its arguments, are refused.
- The method is found, and its visibility checked, as for a call. A
  variant is found before a method of the same name, as `Shape.Circle(2)`
  constructs.
- Two function types that differ only in a parameter's mode do not
  convert; the error names both modes and the closure.

**What was found on the way, and fixed in the same change (Eric: "can you
fix these").**
- A variant and a method of the same name were both accepted
  (`Shape.Square` the variant, `s.Square()` the method). Now the method's
  declaration is refused: `Type.name` names one thing.
- Where a name has an observing and an owned form (D117's `first`),
  `Type.name` is the observing one, and a wanted function type whose first
  parameter is taken by value selects the owned one, as the receiver's
  ownership does at a call.
- Methods the compiler implements itself (`List[i32].len`) have no
  function to name. Their value is the closure a person would write,
  `(x, a) => x.method(a)`, which Sema writes and checks like any other:
  the receiver in the method's mode, each argument at the type its
  BuiltinSigs row declares. The tree is frozen before Sema; these nodes
  enter through one named, counted door (`AstPool.add_adapter_node`).
- A closure's `mut` parameter was dropped by the closure body (wrong
  code since D218's closure layer: `push(ys, 5)` through
  `(mut r: List[i32], a) => r.push(a)` freed the caller's list). Fixed.
- The count Eric asked for: 13 wrapper closures of the shape
  `(x) => x.m()` and 17 arguments of the shape `it.m()` in the whole tree
  (migrated corpora excluded). 12 can be written `Type.method` now
  (`CStr.to_str_lossy`, `CStr.to_owned`, `str.to_owned`, which std
  declares; `Option.map` accepts an observing function), and so can the
  16 that name methods the compiler implements itself (`len` 11, `clone`
  4, `to_upper` 1). 2 cannot (`parse` has its own type parameter). None
  was refused for its mode.

**Reopen if** the bound form turns out to be wanted for `fn` methods, or
the compiler-implemented methods stay unnameable long enough that the
feature reads as broken for std.
