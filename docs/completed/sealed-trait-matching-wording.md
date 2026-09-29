# Proposed wording for #1860 and #1852

Status: exact wording awaits Eric's blessing. The design is already approved
(2026-09-28, option (a)); this document does not reopen it.

## Proposed normative changes

Add `TYPED_BIND_PAT` to `PATTERN` in §grammar:

```
TYPED_BIND_PAT := IDENT ':' TYPE
```

Add to §9.7, Pattern Matching:

> **Trait-object downcast patterns.** In a match whose subject has type
> `&dyn T`, the pattern `name: C` tests whether the object has concrete type
> `C`. `C` must be visible and implement `T`. On a successful match, `name`
> has type `&C` and observes the same object; it preserves the subject's
> view origin and does not copy or take ownership of the object. This pattern
> is rejected for a subject whose type is not `&dyn T`.
>
> If `T` is `@[sealed]`, its closed set of implementors is the domain for
> exhaustiveness. An exhaustive match covers every implementor with an
> unguarded typed binding pattern or a wildcard. A non-sealed trait requires
> a wildcard arm to establish exhaustiveness because its implementor set is
> open. A guarded arm alone does not establish coverage. The ordinary rules
> below determine when a non-exhaustive match is an error or a warning.
>
> The binding remains an observing view when the trait-object place is
> mutable. Mutation uses the trait's `mut fn` methods under the ordinary
> receiver rules; the downcast pattern does not grant write access through
> `&C`. With has no `&mut T` spelling (§15.1). Owned by-value trait-object
> matching is not defined.

Add to §11.3, after its statement that `dyn Trait` is unsized:

> A parameter cannot take a bare `dyn Trait` by value. Use `&dyn Trait` to
> borrow an object or `Box[dyn Trait]` to transfer ownership. Typed downcast
> patterns over borrowed trait objects are defined in §9.7.

## Basis for the wording

The existing §11.3 says "`dyn Trait` is unsized" and describes ownership
through `Box[dyn Trait]`. §11.6 says sealed traits "guarantee a closed set
of implementors, enabling optimizations and exhaustive reasoning." §9.7
defines exhaustive matching, but the grammar currently omits the typed
binding pattern. D22 §2 requires a reference to remain a reference through
pattern projection. These additions give the approved pattern one normative
home and explicitly rule out the former duplicate-owner lowering.

Reference trees checked locally:

- Vale's `Frontend/Tests/test/main/resources/programs/downcast/downcastBorrowSuccessful.vale`
  uses a sealed interface and `ship.as<Raza>()` with result
  `Result<&Raza, &IShip>`: successful downcasting preserves a borrow.
- Go's `doc/go_spec.html`, Type switches, restricts the subject to an
  interface, requires concrete cases to implement it, and gives each
  single-type case binding that concrete type. With retains a view instead
  and uses sealed-ness to establish a closed domain.
- Rust's `library/core/src/any.rs`, `Any::downcast_ref`, returns
  `Option<&T>`. With expresses the same observing relationship through a
  pattern and permits exhaustiveness for a sealed trait.

Mission fit: the subject determines borrowing, so the programmer does not
repeat `&` in the pattern. The explicit concrete type selects the case;
the sealed trait already determines when all cases are covered. No object
is silently copied, moved, or given another owner.

Prediction: Eric approves this wording with high confidence because it
states the approved option (a), preserves D22, and keeps receiver mutation
separate from the observing downcast binding. The unresolved item is the
wording itself, not the design.
