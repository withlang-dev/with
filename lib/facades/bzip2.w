// The bzip2 facade — D64 (spec §16.2b.8 "Buffers"): the one-shot
// buffer-to-buffer surface of the real `bzlib.h` (the one `c_import`
// resolves on the host), exactly what the release UAT program uses. The
// header carries no documentation, so every clause quotes the bzip2 manual
// (bzip2 and libbzip2, version 1.0.8, §3.5 "Utility functions").
//
// Where it lives: as `lib/facades/sqlite3.w` — the project's own facade
// under the repository's `lib/` (§16.2b.1; `c.bzip2` ships none yet), and
// the release UAT copies it into the fresh project as src/facades/bzip2.w.
//
// The three tuning integers (`blockSize100k`, `verbosity`, `workFactor`)
// stay presented: they are the caller's choice, not facts of the facade,
// so nothing fixes them (§16.2b.11 binds a literal only where the facade
// states one meaning).
use c_import("bzlib.h", link: "bz2")

c facade bzip2:
    // "Attempts to compress the data in source[0 .. sourceLen-1] into the
    // destination buffer, dest[0 .. *destLen-1]. If the destination buffer
    // is big enough, *destLen is set to the size of the compressed data,
    // and BZ_OK is returned. If the compressed data won't fit, *destLen is
    // unchanged, and BZ_OUTBUFF_FULL is returned." — `dest` and `destLen`
    // are one `[]mut u8` whose length is the capacity, the produced length
    // is the result, and `source` and `sourceLen` are one `[]u8` (the
    // manual reads `source`; the header's `char*` is not const, and the
    // pairing states it is an input). `ok BZ_OK` is the status contract:
    // `Result[usize, BZ2_bzBuffToBuffCompressError]`.
    fn BZ2_bzBuffToBuffCompress
        buffer param dest capacity param destLen inout
        buffer param source len param sourceLen
        ok BZ_OK
    // "Attempts to decompress the data in source[0 .. sourceLen-1] into the
    // destination buffer, dest[0 .. *destLen-1]. If the destination buffer
    // is big enough, *destLen is set to the size of the uncompressed data,
    // and BZ_OK is returned. If the compressed data won't fit, *destLen is
    // unchanged, and BZ_OUTBUFF_FULL is returned."
    fn BZ2_bzBuffToBuffDecompress
        buffer param dest capacity param destLen inout
        buffer param source len param sourceLen
        ok BZ_OK
