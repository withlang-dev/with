# D75 — `once` parameters, fills, distinct casts, payload discriminants, variadic definitions

**Laws:** 6, 5 (docs/mission.md).

**Date:** 2026-09-28. **Status:** BDFL ruling (Eric, on the exact words:
"1. approved … 5. approved"; 6 was agreed on 2026-09-27, "fair. I agree.").

1. **Non-`move` closure arguments (§12.4).** The sentence said such an
   argument is ephemeral "exactly as a `&T` parameter is" and also that it
   "may not be … returned" — but a `&T` parameter may be returned (§3.4). The
   explicit list stands (D63 (3): not storable or returnable; Swift's
   non-escaping parameters behave the same); "exactly as a `&T` parameter
   is" is dropped. Implemented by #1698.
2. **Payload discriminants without a representation (§4.4a, #1769).** An
   explicit `= N` on any variant of an enum with no representation type makes
   it a discriminant enum in the default integer representation, payload
   variants or not — as a fieldless one already was (#309) and a
   backing-less `@[flags]` enum is (D71). The value is range-checked (#1003).
3. **Distinct casts (§4.5, #1802).** A cast of an owned value into or out of
   its distinct type moves it and the distinct type has its underlying type's
   destructor; a cast to a view (`n as &str`) or through a reference borrows.
   Before, `s as Name` left the buffer with `s` and `n as str` made a second
   owner (a double free). The cast's target states the mode, as a parameter's
   type does.
4. **Fills (§4.3a, #1814).** `[value; N]` evaluates `value` once per element,
   in order, at every N; N is a compile-time constant (§9.1b). Before, a
   literal N ≤ 64 evaluated per element (parser expansion) and a larger or
   `const` N once, so a program changed meaning at N = 65. Per element keeps
   `[s.clone(); 100]` and `[Vec.new(); 8]` meaning what they say (Rust, Zig
   and Swift evaluate once and refuse or copy; With picks the user's reading).
5. **`once` parameters (§12.4, #1604).** Across a bundle boundary a consuming
   closure may be passed only to a parameter declared `once`
   (`f: once fn(A) -> R`); the compiler rejects a body that may invoke it
   twice and the bundle interface records it; within one compilation `once`
   is permitted, checked, never required. Replaces "(deferred)".
6. **Variadic definitions (§16.2b.5, #1678).** The Zig shape agreed on
   2026-09-27: a trailing `...` parameter, the C calling convention, `unsafe`
   to call; `var ap = va_start()` yields the target's `c_va_list` and
   `ap.arg[T]()` is lowered per target by the compiler — no inline assembly;
   the migrator emits this form for a variadic C definition instead of
   omitting its body.

Implementation status: 1, 2 and 4 are implemented on stack #1813/#1821 and
the closure layer; 3, 5 and 6 are NON-COMPLIANT until their fixes land.
