// The zlib facade — D64 (spec §16.2b.8 "Buffers", §16.2b.11 "Fixed
// arguments"): the first facade written against the buffer-pairing ruling,
// over the real `zlib.h` (the one `c_import` resolves on the host), and
// exactly the surface the release UAT program uses — `compress`,
// `uncompress` and `zlibVersion`. Every sentence a clause relies on is
// quoted beside it, from that header.
//
// Where it lives: as `lib/facades/sqlite3.w` — the project's own facade
// under the repository's `lib/` (§16.2b.1; `c.zlib` ships none yet), and
// the release UAT copies it into the fresh project as src/facades/zlib.w.
//
// A pairing is stated, never inferred from the C types (§16.2b.8): the
// header alone does not prove that `destLen` is `dest`'s capacity, and a
// wrong pairing hands C a wrong length. The presented calls take slices —
// no pointer, no length, no `unsafe`:
//
//     let n = compress(out, src)?        // -> usize, the bytes written
//     let m = uncompress(back, out[..n])?
//
// The length C writes back is bounds-checked against the capacity before
// it becomes a With value, and the caller's slice is never modified.
use c_import("zlib.h", link: "z")

c facade zlib:
    // "Compresses the source buffer into the destination buffer. sourceLen
    // is the byte length of the source buffer. Upon entry, destLen is the
    // total size of the destination buffer … Upon exit, destLen is the
    // actual size of the compressed data." — `dest` and `destLen` are one
    // `[]mut u8` whose length is the capacity C receives, and the produced
    // length is the result; `source` and `sourceLen` are one `[]u8`.
    // "compress returns Z_OK if success, Z_MEM_ERROR if there was not
    // enough memory, Z_BUF_ERROR if there was not enough room in the
    // output buffer." — the status contract under which the length is
    // presented: `Result[usize, CompressError]`.
    fn compress
        buffer param dest capacity param destLen inout
        buffer param source len param sourceLen
        ok Z_OK
    // "Decompresses the source buffer into the destination buffer.
    // sourceLen is the byte length of the source buffer. Upon entry,
    // destLen is the total size of the destination buffer … Upon exit,
    // destLen is the actual size of the uncompressed data."
    // "uncompress returns Z_OK if success, Z_MEM_ERROR if there was not
    // enough memory, Z_BUF_ERROR if there was not enough room in the output
    // buffer, or Z_DATA_ERROR if the input data was corrupted or
    // incomplete." — on failure the length is not presented (§16.2b.8),
    // even though "in the case where there is not enough room, uncompress()
    // will fill the output buffer with the uncompressed data up to that
    // point": a partial fill is the error's, not a result.
    fn uncompress
        buffer param dest capacity param destLen inout
        buffer param source len param sourceLen
        ok Z_OK
    // "The application can compare zlibVersion and ZLIB_VERSION for
    // consistency." — static text: the library's version string, presented
    // as `Option[CStr]` under the C name (§16.2b.7, §16.2b.8).
    fn zlibVersion
        returns static CStr
