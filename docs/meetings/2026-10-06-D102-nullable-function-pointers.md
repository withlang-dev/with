# D102 — `extern "C" fn` is non-null; a nullable C function pointer is a pointer-sized `Option`, placed by direction

**Laws:** 4, 6 (docs/mission.md).

Ruled by Eric, 2026-10-06 (#2215, #2216).

## Context

c_import mapped every C function pointer to the non-null
`unsafe extern "C" fn`, against §16.2b.2's "unknown nullability is
nullable"; D101's zero-validity then refused `zeroed()` on any record
holding one (zlib's `z_stream`). Worse, `null` was accepted as a value of the
safe `extern "C" fn`, and safe code could call it: a SIGTRAP with no
diagnostic and no `unsafe` (#2216).

## Ruling

1. `extern "C" fn` and `unsafe extern "C" fn` are non-null; `null` is not a
   value of either. The nullable form is `Option[...]` of the type.
2. The layout is an ABI guarantee, written in `with-abi.md` §3:
   `Option[extern "C" fn]`, `Option[unsafe extern "C" fn]` and `Option[&T]`
   are exactly pointer-sized, `None` is null. (Measured: already 8 bytes.)
3. c_import maps at the use site, not the typedef: a typedef is the non-null
   type; a record field, a return and an out-parameter receiving a callback
   (`fn_t *out`) are `Option` (C hands it to the program); a parameter stays
   non-null (the program hands it to C).
4. A field is `Option` in both directions: writing `None` into zlib's
   `zalloc` requests the default allocator.
5. A facade widens a parameter whose C contract accepts NULL with
   `nullable param N` (§16.2b.8); `sqlite3_exec`'s callback is the first
   user.
6. Implicit `Some` is deferred to its own change across all `Option` sites,
   expected yes, before stable (#2217).

The migrator translates a call through a C function-pointer field as an
unwrap that panics, where C would call NULL with undefined behavior.

## References

Zig translate-c wraps C function pointers as `?*const fn`
(`Translator.zig` 1232–1236). Rust guarantees `Option<[unsafe] extern "abi"
fn>` is pointer-sized with `None` = null (`option.rs` 143). Swift imports
them optional unless `_Nonnull`.
