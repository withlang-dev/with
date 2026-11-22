// zlib 1.4, the version `with get c.zlib` pins. Every citation is a line of
// that package's include/zlib.h.
//
// The proof engine finds three unary destroyers of gzFile_s (gzclose,
// gzclose_r, gzclose_w) and cannot pick the drop; the library's own header
// does.
//
// A z_stream is initialized in place, by one of two families over the one
// record: inflate and deflate. No draft can choose between them, so each is
// stated. The storage begins zeroed, which the header requires of the
// fields an initializer reads (line 235: "zalloc, zfree and opaque must be
// initialized before by the caller"; line 385 adds next_in and avail_in for
// inflateInit; a zero zalloc and zfree select the default allocator).
// The functions `inflateInit` and its kin are macros (lines 1942 to 1951)
// over the `_`-suffixed functions, which take the header's version text and
// the caller's stream size.
c facade zlib:
    resource GzFileS wraps *mut gzFile_s
        drop gzclose    // zlib.h 1.4 line 1761, gzclose: "Flush all pending output for file, if necessary, close file and deallocate the (de)compression state"
        destroys gzclose_r    // zlib.h 1.4 line 1775: "Same as gzclose(), but gzclose_r() is only for use when reading"
        destroys gzclose_w    // zlib.h 1.4 line 1776: "gzclose_w() is only for use when writing or appending"
    resource Inflater wraps z_stream
        init inflateInit_(self), ok Z_OK    // zlib.h 1.4 line 393: "inflateInit returns Z_OK if success"; line 1944: inflateInit(strm) is inflateInit_((strm), ZLIB_VERSION, (int)sizeof(z_stream))
        init inflateInit2_(self), ok Z_OK    // zlib.h 1.4 line 902: "inflateInit2 returns Z_OK if success"; line 1949: inflateInit2(strm, windowBits) is inflateInit2_((strm), (windowBits), ZLIB_VERSION, (int)sizeof(z_stream))
        drop inflateEnd    // zlib.h 1.4 line 527, inflateEnd: "All dynamically allocated data structures for this stream are freed."
    resource Deflater wraps z_stream
        init deflateInit_(self), ok Z_OK    // zlib.h 1.4 line 245: "deflateInit returns Z_OK if success"; line 1942: deflateInit(strm, level) is deflateInit_((strm), (level), ZLIB_VERSION, (int)sizeof(z_stream))
        init deflateInit2_(self), ok Z_OK    // zlib.h 1.4 line 610: "deflateInit2 returns Z_OK if success"; line 1946: deflateInit2 passes ZLIB_VERSION and (int)sizeof(z_stream) last
        drop deflateEnd    // zlib.h 1.4 line 369, deflateEnd: "All dynamically allocated data structures for this stream are freed."
    fn inflateInit_
        param version fixed ZLIB_VERSION    // zlib.h 1.4 line 1945: the macro passes ZLIB_VERSION
        param stream_size fixed sizeof(z_stream)    // zlib.h 1.4 line 1945: the macro passes (int)sizeof(z_stream)
    fn inflateInit2_
        param version fixed ZLIB_VERSION    // zlib.h 1.4 line 1950: the macro passes ZLIB_VERSION
        param stream_size fixed sizeof(z_stream)    // zlib.h 1.4 line 1951: the macro passes (int)sizeof(z_stream)
    fn deflateInit_
        param version fixed ZLIB_VERSION    // zlib.h 1.4 line 1943: the macro passes ZLIB_VERSION
        param stream_size fixed sizeof(z_stream)    // zlib.h 1.4 line 1943: the macro passes (int)sizeof(z_stream)
    fn deflateInit2_
        param version fixed ZLIB_VERSION    // zlib.h 1.4 line 1948: the macro passes ZLIB_VERSION
        param stream_size fixed sizeof(z_stream)    // zlib.h 1.4 line 1948: the macro passes (int)sizeof(z_stream)
