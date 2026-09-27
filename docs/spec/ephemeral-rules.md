# 22. Ephemeral Type Rules

The programmer writes no lifetime or ephemerality annotations. The
compiler carries the origin and provenance facts needed to make that safe.

Type-level ephemerality is structural. References carry origin
constraints. Declared-ephemeral types are ephemeral by declaration.
Aggregates and generic containers whose type structurally contains an
ephemeral component are ephemeral by structure, such as `Vec[&T]`. This
determines which type shapes can carry ephemeral constraints.

Value-level ephemerality is provenance-tracked. Binding-level
ephemerality, returned-origin sets, task capture ephemerality, closure
capture ephemerality, assignment propagation, call propagation,
returned-view checking, and escape checks require deterministic
provenance analysis.

Tasks are value-level. `Task[T]` has one spelling whether ephemeral or
non-ephemeral. A task binding is ephemeral when the task captures or
depends on an ephemeral origin. That fact is inferred and propagated, not
determined from the structural type alone.

Closures and callable values carry summaries. An implementation may
encode captures structurally in anonymous closure types, but the spec
guarantee is a compiler-carried callable summary: captures, origin sets,
ephemerality, and `may_suspend` facts are carried across closure,
function pointer, trait object, and wrapper boundaries.

The analysis is modular and inferred: intra-procedural dataflow inside
each function body, plus inferred summaries across interfaces, including
returned-origin sets, task ephemerality, closure/callable capture
provenance, and `may_suspend` facts. The user writes no lifetime or
ephemerality annotations.

The analysis is deterministic and conservative. Verdicts are
reproducible. If the compiler cannot prove that an ephemeral value does
not escape, it rejects. False rejection of actually-safe code is compiler
precision debt, not user ceremony.

### 22.1 Rules

| # | Condition | Result |
|---|-----------|--------|
| 1 | Type is `&T`, `StrView`, `&[T]` | Ephemeral |
| 2 | Type is declared `ephemeral` | Ephemeral |
| 3 | Generic `F[T]` where `T` is ephemeral | Ephemeral |
| 4 | Struct has ephemeral field but is not marked `ephemeral` | Reject definition |
| 5 | `let x = expr` where expr is ephemeral | Bind `x` as ephemeral |
| 6 | Enum variant payload declared with ephemeral type | Reject unless the enum is marked `ephemeral` |
| 7 | Ephemeral value inserted into heap container | Container becomes ephemeral |
| 8 | Function returns ephemeral type | Callers inherit restriction |
| 9 | Escaping closure captures ephemeral value | Reject |
| 10 | Guarded `with` block (Form 1) result is ephemeral | Reject |

Rule 7: A `Vec[T]` where `T` is ephemeral becomes an ephemeral `Vec`. It
cannot be stored in a struct or sent to another thread; returned from a
function, it makes the caller's binding ephemeral (rule 8). This
enables common patterns like collecting tokens from a parser:

```
// Token is ephemeral (contains StrView)
let tokens = with Vec.new() as mut toks:
    while let Some(tok) = parser.next_token():
        toks.push(tok)
// tokens: Vec[Token] is itself ephemeral — valid only in this scope
// Cannot store tokens in a struct; returning it makes the caller's binding ephemeral
```

This is consistent with Rule 3 (generic container inherits
ephemerality from its type parameter).

Rule 10 applies only to Form 1 (guarded access). The guard is
released when the block exits, so any ephemeral borrowing from the
guard's payload would dangle. Forms 2 and 3 desugar to plain
`let`/`var` blocks — their results follow normal ephemeral rules
(rules 5, 8).

### 22.2 Closure Escaping (v1.0)

A closure is non-escaping if and only if it appears as a direct
argument to a function call. All other closures are escaping.

### 22.3 Diagnostic Contract

Because the programmer cannot annotate lifetimes or ephemerality, the
diagnostic is the only interface to this analysis. Every rejection
produced by the ephemeral/origin rules (§22.1) and the view-liveness
rules (§21.1) must report, with source locations:

1. where the borrowed/ephemeral value was created (the origin),
2. where it escapes or is invalidated (the violation), and
3. where it is later used, when a later use is what makes the program
   unsafe.

The diagnostic must also name at least one idiomatic remedy
(clone/copy out, collect into owned data, use a handle, restructure
into a `with` scope, or take `&T`). A single-location "value escapes"
error does not satisfy this contract. False rejection of safe code is
compiler precision debt; an unclear rejection is diagnostic debt.
Both are compiler bugs, never user obligations.

When a contextual Copy annotation would make an invalidated view independent,
the diagnostic must explain that distinction and provide a machine-applicable
fix when possible:

```text
error: cannot mutate `counts` while `count` is a live view into it
 --> counts.clear()
note: `count` views a value stored in `counts`
note: `count` is used after this mutation
help: take an independent Copy value:
      let count: i32 = counts.get("api").unwrap()
```

For a non-`Copy` join, the diagnostic must explain both branch contracts:

```text
error: `??` would need to copy `Vec[Job]`, which is not `Copy`
 --> queues.get("ready") ?? Vec.new()
note: the successful branch is `&Vec[Job]`, a view into `queues`
note: the default branch is an owned `Vec[Job]`
help: clone the found value into an independent Vec:
      queues.get("ready").cloned() ?? Vec.new()
help: or borrow the default too:
      queues.get("ready") ?? &empty
```

A cloning suggestion is emitted only when the pointee implements `Clone`. A
borrowed-default suggestion is emitted only when the proposed default has a
lifetime valid for the resulting view. When neither applies, the diagnostic
must explain that a borrowed map cannot yield ownership and may suggest
`remove` when ownership transfer matches the operation. It must not imply that
an annotation alone can copy a non-`Copy` value.

---
