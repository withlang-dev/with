# 16.6 Function Pointers

`fn(...) -> T` is a With callable value. It may carry closure context and is
not C ABI compatible.

`extern "C" fn(...) -> T` is a raw C ABI function pointer. It is pointer-sized,
`Copy`, and may be stored in `repr(C)` structs or passed to C imports. Named
functions and non-capturing closures coerce to `extern "C" fn` when their
signature matches. Capturing closures do not coerce, because a C function
pointer has no place to store With closure context.

An `extern "C" fn` (and an `unsafe extern "C" fn`) is never null: `null` is
not a value of the type. A function pointer that may be null is
`Option[extern "C" fn(...) -> T]`, whose `None` is the null pointer
(`with-abi.md` §3 guarantees its layout).

Function pointer type parameters may be written with or without names:

```
extern "C" fn(i32, i32) -> i32
extern "C" fn(lhs: i32, rhs: i32) -> i32
```

**Imported function pointers (D102).** `c_import` places nullability by the
direction the pointer travels (§16.2b.2: unknown nullability is nullable,
and only what removes capability is inferred):

- a C typedef of a function-pointer type imports as the non-null
  `unsafe extern "C" fn` type;
- a record field, a function's return, and an out-parameter that receives a
  function pointer (`fn_t *out`) are where C hands one to the program, so
  each is `Option[unsafe extern "C" fn(...)]` at that position;
- a function parameter is where the program hands one to C, so it stays the
  non-null type. A facade widens a parameter whose C contract accepts NULL
  with `nullable param N` (§16.2b.5).

A record field is `Option` in both directions: writing `None` is how a C API
such as zlib's `zalloc` is asked for its default.
