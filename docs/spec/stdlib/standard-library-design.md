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

All collection types provide `.len()` returning `Int` (i64) — signed, so
`v.len() - 1` and countdown/index arithmetic just work; a held container
always has a length, so length is never wrapped in `Option` (decisions.md
D11). Convenience narrowing methods (`.len32()`, `.ulen32()`) panic on
overflow; `.len64()` is an identity alias of `.len()`. The same signed
convention applies to iterator `count()` and `position()` indices; `size`
/ `align` type-layout constants stay `usize` (memory-layout / FFI, a
distinct category). *Implementation note:* the compiler's sema surface
still returns `usize` until #630 lands the flip — the spec leads here; do
not revert this to `usize`.

All collection types implement `Contains[T]` (§11.7), enabling the
`in` operator for membership tests. See §9.9.

For complete API specifications, see `docs/libstd-spec.md`.
