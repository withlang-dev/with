# D175 — Runtime globals initialize in dependency order; an access whose completed initialization cannot be established is not safe code

**Status:** Ruled (Eric, 2026-10-30). Replaces §9.1c's declaration-order
sentence. Implementation pending: the compiler is non-compliant until it
conforms.

## Question

```
let doubled = later * 2
let later: i64 = xs.len()
```

printed `0`: initializers ran in declaration order, and `doubled` read
`later` before its initializer had run. For a type that owns heap memory
the read is zeroed storage, a memory-safety hole. Refusing the read
breaks the libxml2 UAT, whose modeled headers declare
`QUAD_MIN = LLONG_MIN` before `LLONG_MIN`.

## Ruling

Option (a), dependency order, with the soundness of indirect
dependencies made an explicit requirement:

> Runtime globals initialize before `main`, on the initial thread, in
> dependency order. A global's initializer runs after every global it may
> read, including through transitively called functions. Among eligible
> globals, declaration order decides. Initialization cycles are errors.
> Safe code may not access a global whose completed initialization cannot
> be established.

> Go's specification expressly acknowledges that dynamically dispatched
> calls can create dependencies its static analysis doesn't detect. For
> With, an uninitialized global containing a resource isn't necessarily a
> valid zero value. An undetected dependency could therefore be a
> memory-safety defect, not merely an unexpected initialization result.

> The implementation must define how it handles indirect calls and
> dependencies it cannot prove. Conservatively rejecting an unprovable
> initialization access is one safe option; a narrowly scoped runtime
> initialization check is another. I would not introduce a guard on every
> ordinary global access.

## Reference

Go initializes package-level variables stepwise, selecting "the earliest
variable in declaration order and ready for initialization", with
dependencies computed transitively through function bodies
(`.reference/go/doc/go_spec.html`, Package initialization). Zig's
namespace-level variables are order-independent and comptime; Rust's
statics are const-evaluable; Swift guards each global with a lazy
initializer.
