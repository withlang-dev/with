# 16.6 Function Pointers

`fn(...) -> T` is a With callable value. It may carry closure context and is
not C ABI compatible.

`extern "C" fn(...) -> T` is a raw C ABI function pointer. It is pointer-sized,
`Copy`, and may be stored in `repr(C)` structs or passed to C imports. Named
functions and non-capturing closures coerce to `extern "C" fn` when their
signature matches. Capturing closures do not coerce, because a C function
pointer has no place to store With closure context.

Function pointer type parameters may be written with or without names:

```
extern "C" fn(i32, i32) -> i32
extern "C" fn(lhs: i32, rhs: i32) -> i32
```
