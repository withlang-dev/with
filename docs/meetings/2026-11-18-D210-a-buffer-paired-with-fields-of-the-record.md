# D210 — A buffer paired with fields of a resource's record

**Laws:** 1 (the program has determined the bytes to read and the room to
write; four field assignments under `unsafe` per call are ceremony), safety
(no pointer into the program's slice stays in the record between calls).

**Date:** 2026-11-18. **Status:** ruled by Eric. The spec words are derived
and come to him as a diff with the implementation.

**Context.** #3173: `deflate(strm, flush)` reads through `strm->next_in` /
`avail_in` and writes through `strm->next_out` / `avail_out`. §16.2b.8 pairs
a buffer with parameters only, so a program set the four fields through
`.repr` under `unsafe`. 1,342 functions in 17 libraries were raw as "the
record holds a pointer"; the step functions of each stream library need this
clause.

**Ruling.**

- `buffer field P remaining field N` on an fn item that lends the resource.
  One word, `remaining`, for the input and the output buffer.
- Before the call the wrapper stores the slice's pointer and length in the
  two fields. An empty slice is stored as a non-null pointer with count 0:
  `deflate` rejects a null `next_out`.
- A slice longer than the count field can hold (zlib's are 32-bit) is passed
  as at most the field's maximum and reported as partial progress, never
  truncated.
- After the call the wrapper reads the count back (consumed or produced is
  what went in minus what remains; more than went in is a contract failure
  naming the function), then clears the fields.
- The presented operation returns a generated result record, not a tuple.
- A library that reads the pointers between calls is not described by this
  clause and stays raw.

**Why clear the fields.** Rust's `flate2` leaves the pointers dangling in
the record and never reads them. Clearing costs two stores and removes the
dangling pointer, which is what lets the slices go after the call.

**Not covered.** A position record passed by pointer (zstd's `{src, size,
pos}`) and a pointer-to-pointer pair (brotli) are other shapes.

**Reopen if** a stream library needs the pointer to persist between calls
for a documented reason.
