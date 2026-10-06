# D101 — `T.zeroed()` is safe on zero-valid C records; the facade's in-place storage uses it

Ruled by Eric, 2026-10-06.

## Context

D100's field privacy needed an alias to stop standing in for its target's
declaration. That also closed a hole: a struct literal written through an
alias skipped the missing-field check (§4.3 rule 2), and lowering filled the
missing fields with an implicit default. The C facade generator depended on
it: in-place storage was rendered `Repr {}`, which compiled only because the
representation was a typedef alias, and failed on any C record with a union,
callback or nested-record field. §16.2b.3 already said the storage "begins
as `Representation.zeroed()`"; nothing implemented it.

## Ruling

A safe, compiler-provided `T.zeroed()` on C records (declared by `c_import`
or `@[repr(C)]`), and the facade generator emits `Repr.zeroed()` instead of
`Repr {}`. The alias fix stays.

`zeroed()` is safe only when all-zero bits are a value of every field's With
type, defined structurally: integers, floats, `bool`, raw pointers and
nullable function pointers are zero-valid; an enum is when 0 is a declared
discriminant; unions, arrays and records are when everything inside them is.
On any other record `zeroed()` is an error naming the field. (The same
all-zero-storage reasoning as D72.)

## References

Zig `std.mem.zeroes` memsets `extern` structs and unions (safe); Swift's
ClangImporter synthesizes a zero-initializing `init()` for every imported C
struct; Rust's `mem::zeroed` is `unsafe`.

## Consequences

- c_import maps a C function-pointer field to a non-null `extern "C" fn`, so a
  record holding one (zlib's `z_stream`, stdlib's `sigevent`) is not
  zero-valid until such fields import as nullable.
- `with migrate` should map `struct T x = {0};` and `memset(&x, 0, sizeof x)`
  to `T.zeroed()`.
