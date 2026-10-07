# 18.6 Standard Library Design

The standard library is layered. Users write idiomatic With code
against `std.*` modules. They should never need `c_import` for
ordinary programming tasks.

**Layer 0: `c_import`** — compiler built-in. The mechanism by which
the standard library itself accesses platform APIs.

**Layer 1: `std.os`** — thin safe wrappers around platform APIs
(libc, POSIX, Win32). Written using `c_import` internally. Not
intended for direct use by application developers.

**Layer 2: `std.*`** — idiomatic, safe, cross-platform APIs. This is
what users import.

All collection types provide `.len()` returning `isize`, the signed
pointer-width integer: 64 bits on every supported target but wasm32, where
it is 32 (D108). Signed, so `v.len() - 1` and countdown/index arithmetic
just work; a held container always has a length, so length is never
wrapped in `Option` (D11). Pointer-width, so a length meeting C's `size_t`
or `ssize_t` at a facade is a sign change on every target and nothing
more. `Int` stays the fixed 64-bit alias (§4.2) for a program that wants
one width. Convenience narrowing methods (`.len32()`, `.ulen32()`) panic
on overflow; `.len64()` is `.len()` widened. The same signed pointer-width
convention applies to iterator `count()` and `position()` indices; `size`
/ `align` type-layout constants stay `usize` (memory-layout / FFI, a
distinct category). *Implementation note:* the compiler's surface still
returns `i64` until #2262 lands the flip — the spec leads here.

All collection types implement `Contains[T]` (§11.7), enabling the
`in` operator for membership tests. See §9.9.

For complete API specifications, see `docs/libstd-spec.md`.
