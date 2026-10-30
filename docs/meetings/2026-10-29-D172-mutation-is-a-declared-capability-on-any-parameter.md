# D172 — Mutation is a declared capability on any parameter; exclusive access begins when the call does; read-path caches are a sealed std type (ruled)

**Laws:** exactly as safe as Rust; declare the guarantees that must remain
stable, infer what can safely improve the programmer's experience.

**Date:** 2026-10-29. **Status:** ruled (Eric).

**Decision.**

1. **The receiver mode is enforced for every mutation.** A `fn` receiver
   is read-only for all writes through it, including std container
   methods (`push`, `insert`, `clear`, …). The gap that let a `fn` grow a
   list while a caller held a view into it (a use-after-free in safe
   code) must be closed under this ruling. The ruling is implemented when
   the rebuilt compiler passes the gate and both batteries with the check
   enforced and the regression test in place. `mut fn` stays declared,
   never inferred (D7).
2. **Any parameter may be `mut`.** `mut p: T` grants the callee exclusive,
   in-place access to the caller's place for the duration of the call,
   without transferring ownership. It is the receiver's existing
   `mut self: Self` mode, generalized; a receiver is a first parameter.
   It is a parameter mode, not a type: there is still no `&mut T` in safe
   code.
3. **Exclusive access begins at call activation.** A call proceeds in
   four steps: (1) every argument expression is evaluated left to right,
   except that a `mut` argument's place is not moved or copied; (2) each
   `mut` receiver or argument place is resolved, one containing an index
   projection before step 1 begins, any other variable, field path, or
   auto-deref through an owning pointer after step 1 ends; (3) the
   exclusivity rules are checked against what step 1 produced; (4)
   exclusive access is activated and the callee is entered. An argument
   that mutates the container an index projection reads is an error.
4. **Ordinary memoizing methods are `mut fn`.** A method that fills a
   cache mutates, and says so.
5. **Read-path caches use `std`'s `Memo[K, V]`,** built on a
   compiler-known marker type for interior mutability. The marker is
   `unsafe` to use directly; general interior mutability does not enter
   the safe language. `Memo` returns values by copy, never hands out a
   view into itself, offers no callback-taking operations, and is not
   `Sync`. `K`'s equality and hashing must be compiler-generated (no
   `key()` projection anywhere in `K`), and `V` must be reference-free:
   no views, no shared-representation values (`str`, slices), no raw
   pointers. The first version is intended for ID-like keys and values.
6. **Per-field mutation footprints are planned, not ruled.** Within a
   package, the compiler may later infer which fields a `mut fn` writes,
   so a view of an untouched field survives the call. The declared mode
   remains the contract across packages and the floor within one.

**Why.**

- Self-hosting found it. Enforcing (1) produced 793 errors of "calling a
  `mut` method through a read-only reference": free functions taking
  `&AstPool` or `&AnalysisReport` and mutating them. Under §3.1 as
  written, a free function that mutates its argument in place had no safe
  spelling. The compiler had been relying on the hole because the safe
  language could not express an ordinary operation.
- (2) removes an arbitrary restriction rather than adding a concept:
  there is no reason the ability to mutate in place should depend on
  being the first parameter. Every reference language that checks safety
  statically can spell it (Swift `inout`, Mojo `mut`, Rust `&mut T`).
- (3) is deliberately broader than Rust's two-phase borrows, which allow
  `vec.push(vec.len())` but reject `vec.push(vec.pop().unwrap())`. Rust
  must reject the second because it reserves `&mut vec` before
  evaluating arguments. In With a `mut` receiver or argument is a place,
  so access can start at activation. Late resolution is safe for paths
  without side effects (fields, auto-deref) and handles an argument that
  replaces a field's contents or frees an owning pointer's pointee. Index
  projections are resolved early because evaluating the index late would
  reorder its side effects; the cost is that a mutating argument can
  invalidate the address, which is therefore an error. Whether an
  argument mutates a place is read from declared modes, never inferred.
- (4) and (6) together make honest caching cheap: with footprints,
  `get_sig` writing only `sig_cache` does not block a caller's view of any
  other field. Footprints do not help a caller that holds only `&T`;
  that is (5)'s case.
- (5) is sound because no reference into the cache ever leaves it, so no
  write can invalidate one. Compiler-generated equality and hashing
  remove the last path for user code to run while the table is
  mid-operation; a reference-free `V` ensures nothing copied out of the
  cache can refer back into it.
- The receiver mode stays declared because it is the one bit a reader
  needs at every call ("is my view still valid?"), and because inferred
  mutation is transitive. The declared mode is a floor: code written
  against signatures never breaks when a body changes. Footprints only
  relax restrictions above that floor (the D51 asymmetry).

**Considered and rejected.**

- Inferring receiver modes, in general or for private methods only. It
  gives `fn` two meanings, makes "does this call mutate?" a call-graph
  question in exactly the code where it is asked most, and leaves no
  stable subset of callers.
- Keeping §3.1 and restructuring the compiler into methods and returned
  values: hundreds of edits to express an operation the language should
  have.
- Deferring the fix: the use-after-free stays possible in safe code.
- General interior mutability (`Cell`/`RefCell`): a large hole for a
  narrow need.

**Spec changes.**

§3.1 Reference Types, second paragraph.

Before:
> With has a single reference type: `&T`. There is no `&mut T` in safe
> code. Mutation is expressed through owned values (`mut self: Self`
> receivers), `with` scoped access, and `IndexPlace` projections.

After:
> With has a single reference type: `&T`. There is no `&mut T` in safe
> code. Mutation in place is a parameter mode, not a type: a `mut`
> receiver or a `mut` parameter (§3.8a) grants the callee exclusive
> access to the caller's place for the duration of the call. Mutation is
> otherwise expressed through owned values, `with` scoped access, and
> `IndexPlace` projections.

§3.2 Aliasing Rule, the list of mutations.

Before:
> - Calling a `mut self` method on the place (`x.push(v)`)

After:
> - Calling a `mut self` method on the place (`x.push(v)`), or passing
>   the place to a `mut` parameter (§3.8a)

§3.2, last paragraph.

Before:
> A `mut self` receiver is **exclusive** for the duration of the call:
> an argument to the same call may not retain access to the receiver's
> place — a reference to it or one of its fields, an iterator or view
> over it, or a shared-representation value (`str`, slice) read from
> its fields. Bind such values to a local before the call.

After:
> A `mut` receiver or `mut` parameter is **exclusive** for the duration
> of the call: no other argument of the same call may retain access to
> its place — a reference to it or one of its fields, an iterator or view
> over it, a shared-representation value (`str`, slice) read from its
> fields, or the same place passed to a second parameter of either mode.
> Arguments to `mut` parameters naming structurally disjoint fields
> (§3.6) are not the same place. Exclusivity begins at call activation
> (§3.2a).

New §3.2a Access Activation:
> A call proceeds in four steps:
>
> 1. Every argument expression is evaluated, left to right. A `mut`
>    argument's place is not moved or copied by this step.
> 2. Each `mut` receiver or `mut` argument place is resolved. A place
>    containing an index projection is resolved before step 1 begins.
>    Any other place (a variable, a field path, or an auto-deref through
>    an owning pointer, §3.7) is resolved after step 1 ends.
> 3. The exclusivity rules of §3.2 are checked against what step 1
>    produced.
> 4. Exclusive access is activated and the callee is entered.
>
> An argument's evaluation may therefore mutate a place that a `mut`
> receiver or argument of the same call names, provided its result
> retains no access to that place when the call begins:
>
> ```
> pool.add_node(pool.make_node(kind))   // make_node runs, then add_node
> state.child.update(state.reset())
> // the reset happens first; the child updated is the one that exists afterward
> ```
>
> An argument mutates a place if it assigns to it, calls a `mut` method on
> it, or passes it to a `mut` parameter, directly or through any call in
> the argument's expression, as determined from declared modes. An
> argument that mutates a container read by an index projection of the
> same call's `mut` place is an error naming both.

§3.8 Auto-Referencing, the "Restriction" paragraph.

Before:
> **Restriction:** Auto-referencing only creates shared borrows
> (`&T`). Mutation uses `mut self` receivers on owned values:

After:
> **Restriction:** Auto-referencing only creates shared borrows
> (`&T`). Mutation in place uses a `mut` receiver or a `mut` parameter
> (§3.8a):

§3.8, the mode paragraph: append after "means whatever the signature says.":
> A `mut T` parameter mutates in place: the argument must be a mutable
> place, and the caller's binding remains valid afterward.

and extend the list of explicit spellings:
> `move x`, `copy x`, `mut x` and `&x` remain available as explicit
> spellings of intent. `mut x` at a call site is valid only where the
> parameter is `mut`; it never grants a mode the signature does not.

New §3.8a Mutable Parameters:
> A parameter declared `mut p: T` receives exclusive, in-place access to
> the caller's argument for the duration of the call. Ownership does not
> transfer: on return the caller's place holds the value as the callee
> left it.
>
> ```
> fn add_node(mut pool: AstPool, node: Node) -> NodeId:
>     pool.nodes.push(node)
>     pool.nodes.len() - 1
>
> var pool = AstPool.new()
> let id = add_node(pool, leaf)      // pool is mutated in place
> ```
>
> - The argument must be a mutable place: a `var` binding, a field or
>   `IndexPlace` projection of one, or a `mut` parameter or receiver of
>   the enclosing function. Passing a `let` binding, a constant, a
>   temporary or a value reached through `&T` is an error.
> - The parameter is a mode, not a type. It cannot be stored in a field
>   or container, returned, or captured by an escaping closure. It may be
>   passed on to another `mut` parameter or used as a `mut` receiver.
> - Exclusivity and activation follow §3.2 and §3.2a.
> - A receiver `mut fn` is the same mode on the first parameter.

§9 (receiver section), add after the definition of `fn` receivers:
> A `fn` receiver is read-only for every write through it: assignment,
> a `mut fn` call, a `mut` parameter, and std container mutations alike.

§19 Safety Boundaries, new paragraph:
> `std` provides one compiler-known type whose contents may change
> through a shared view. Constructing or accessing it directly is
> `unsafe`. The compiler does not assume memory inside it is unchanged
> across calls, whatever the views reaching it, and every backend must
> preserve this: under LLVM, `readonly` and `noalias` are adjusted
> separately, each kept wherever it remains valid; in emitted C, the
> marker's storage is never `const`-qualified and never placed in
> read-only storage. A constant whose type contains the marker is an
> error, since a constant is an immutable static (D127). Safe
> abstractions built on the marker (such as `std`'s `Memo`) must never
> expose a view of its contents. There is no general interior mutability
> in safe code.

`docs/spec/abi`: a `&T` parameter keeps `readonly` and `noalias` except
where `T` contains the marker type, adjusted per §19.

**Implementation, in order.**

1. Spec and tests first: positive and negative fixtures for §3.8a and
   §3.2a, including nested read calls, nested mutating calls returning
   owned values, a returned live view (error), `process(mut p, mut p)`
   and `process(mut p, p)` (errors), `process(mut a.x, mut a.y)`
   (legal), an index projection invalidated by an argument, directly and
   through a method call (errors), and `state.child.update(state.reset())`
   through an inline field and through a `Box` field.
2. The use-after-free regression test, asserted through `--debug-alloc`.
3. A slice of the real failures in `Analysis.w`, `MirLower.w` and
   `ComptimeTransform.w`, before resuming the bulk migration.
4. Classify the remaining errors by distinct function, not occurrence:
   needs a `mut` parameter, needs `Memo`, needs a different design.
   Reconcile the counts (the reported categories sum to 946 of 996).
5. Classify the live-view sites: genuinely dangling, safe by luck, or a
   false alarm a footprint would remove. Report any genuinely dangling
   site as a compiler bug fixed by this change.
6. `Memo` and the marker type, with optimizer-enabled tests on every
   backend the bootstrap uses (LLVM and emitted C), each with a
   single-function case and a cross-function case: a `Memo` updated
   through `&` must show the new value when read after the call. A
   constant containing the marker is a compile-error fixture.
7. The nested-call diagnostic currently cites "§5.4", which is the views
   section; it cites §3.2 and §3.2a.

**Diagnostics.**

- `fn grow` writing through its receiver: "`grow` mutates its receiver
  (`self.xs.push`, line N); declare it `mut fn grow`", with the edit.
- A `mut` method called through `&T`: "`report` is a read-only view; to
  let `audit` mutate it, declare the parameter `mut report: AnalysisReport`",
  with the edit.
- An index projection invalidated: "`pools[i]` is resolved before the
  arguments, and `pools.push_new()` may reallocate `pools`; bind the
  argument to a local first."

**Reopen if:** classification shows most read-only-reference errors need
`Memo` rather than `mut` parameters (then interior mutability's place in
the language is the open question); or footprint inference proves
unsound in a case the second-class reference rule was expected to rule
out.
