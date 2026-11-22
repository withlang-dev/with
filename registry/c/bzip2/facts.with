// bzip2 1.0.8, the version `with get c.bzip2` pins. Every citation is a line
// of the package's own source, bzlib.c, read from the tree `with get`
// fetched for that version.
//
// A bz_stream is initialized in place, by one of two families over the one
// record: compress and decompress. No draft can choose between them, so
// each is stated. Each initializer keeps the stream's address in its state
// (lines 170 and 510: `s->strm = strm`) and every later call checks it
// (lines 414, 474, 815, 868), so the storage has one address until it is
// ended: an in-place resource is pinned by default. The storage begins
// zeroed, and a NULL bzalloc and bzfree select the default allocator (lines
// 165 to 166, 505 to 506). An initializer that fails has stored no state in
// the stream: it returns before `strm->state = s` (lines 203 and 511), after
// freeing what it allocated (lines 182 to 185).
c facade bzip2:
    resource Compressor wraps bz_stream
        init BZ2_bzCompressInit(self), ok BZ_OK    // bzlib.c 1.0.8 line 210: "return BZ_OK;" is the one success return, after the state is stored (line 203); lines 157, 162, 169 and 186 return an error
        drop BZ2_bzCompressEnd    // bzlib.c 1.0.8 lines 476 to 481: frees arr1, arr2, ftab and the state, then sets strm->state to NULL
    resource Decompressor wraps bz_stream
        init BZ2_bzDecompressInit(self), ok BZ_OK    // bzlib.c 1.0.8 line 527: "return BZ_OK;" is the one success return, after the state is stored (line 511); lines 499, 501 to 503 and 509 return an error
        drop BZ2_bzDecompressEnd    // bzlib.c 1.0.8 lines 870 to 875: frees tt, ll16, ll4 and the state, then sets strm->state to NULL
