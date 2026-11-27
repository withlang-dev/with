# D244 — `reads`, `fills`, and `updates` on flat C scalars (delegated)

**Date:** 2026-11-27. **Status:** delegated under D237 (mission-settled; Eric vetoes by revert).

**Laws:** Law 1 (*The compiler never asks for what it already knows*), Law 4 (*A fact is inferred only when being wrong cannot create unsafety*), Law 11 (*The compiler guarantees safety, not correctness of intent*), Law 12 (*The programmer has the last word on what the compiler cannot see*).

---

## Question

C libraries routinely pass pointers to single scalar values as input, output, or in-out parameters:
- `lzma_easy_buffer_encode(..., size_t *out_pos, size_t out_size)` (`c.xz_utils`, #3139)
- `lzma_get_progress(lzma_stream *strm, uint64_t *progress_in, uint64_t *progress_out)` (#3139)
- `XML_GetPropertyBool(XML_Parser p, ..., XML_Bool *out)` / `XML_GetPropertyDouble` / `XML_GetPropertyUInt64` (`c.expat`, #3148)
- `yaml_get_version(int *major, int *minor, int *patch)` (`c.libyaml`, #3149)
- `pcre2_substring_length_byname_8(..., PCRE2_SIZE *length)` (`c.pcre2`, #3152)
- `yyjson_locate_pos(..., size_t *line, size_t *col, size_t *chr)` (`c.yyjson`, #3150)

Under D198, `reads param N`, `fills param N`, and `updates param N` accepted only pointers to complete flat `struct` records (`TY_STRUCT`), rejecting pointers to C scalars (`int`, `size_t`, `uint64_t`, `double`, `bool`) even though D235 (#3119) already stated that `case K: fills T` obeys the rule for `fills` on a fixed parameter and accepts integers, floats, and zero-valid records.

Should `reads`, `fills`, and `updates` accept any flat complete C value type — flat complete records and C scalars (integers, floats, booleans) — while continuing to reject `void`, pointers, function pointers, opaque records, and records holding pointers?

## What the spec says

- §16.2b.5 ("Value records") defines `reads param N` (`&T`), `fills param N` (zero-initialized local returned in the result), and `updates param N` (`mut` parameter) for pointers to flat complete records that hold no pointers.
- D235 (#3119) already established `fills T` for integers, floats, and zero-valid records on variadic cases, explicitly stating "`T` obeys the rule for `fills` on a fixed parameter."

## Mission fit

- **Law 1:** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* A C scalar (`int`, `size_t`, `double`, `bool`) is structurally a flat, complete, zero-valid value — refusing it while accepting a 1-field `struct { int v; }` forces libraries to stay raw and users into `unsafe` for no semantic distinction.
- **Law 4:** *Test: what happens if this inference is wrong?* Nothing is inferred; the contract explicitly claims `reads`/`fills`/`updates param N` with a citation. Passing `&T` (`reads`), a zero-initialized stack slot `&raw mut local` (`fills`), or `&raw mut mut_param` (`updates`) guarantees valid alignment, valid lifetime for the call, non-NULL, and no pointer forgery — identical safety to a flat struct.
- **Law 11:** *Test: is this needed to keep a guarantee, or does it only protect the programmer from themselves?* Restricting `reads`/`fills`/`updates` to `TY_STRUCT` keeps no safety guarantee that flat scalars lack; pointers, `void`, opaque types, and pointer-holding records remain refused.
- **Law 12:** The contract author states whether a C pointer is a single value (`reads`/`fills`/`updates`) or a counted slice (`buffer param P len|capacity param L`), and the compiler honors and checks that claim.

## Decision

Extend `reads param N`, `fills param N`, and `updates param N` to accept pointers to **any flat complete C value**: a flat complete `struct` record or a C scalar (integer, float, or boolean).

- `reads param N`: presents `x: &T` (or `Option[&T]` with `nullable param N`).
- `fills param N`: initializes a local (`T.zeroed()` for a record, `false` for `bool`, `0 as T` for integers and floats), passes `&raw mut local`, and returns the filled value(s) in the operation's result (joining `ok` as `Result[T, E]` or tuples for multiple `fills`, exactly as for flat records).
- `updates param N`: presents `mut x: T`, passing `&raw mut x`.
- `void *`, pointers to pointers (`T **`), function pointers, opaque structs, and records holding pointers remain refused.
- Aligns fixed-parameter `fills` with D235 (#3119)'s `case K: fills T`.
