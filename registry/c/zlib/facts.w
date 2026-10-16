// zlib 1.3.2 (conan-center-index recipes/zlib). The proof engine finds three
// unary destroyers of gzFile_s (gzclose, gzclose_r, gzclose_w) and cannot
// pick the drop; the library's own header does.
c facade zlib:
    resource GzFileS wraps *mut gzFile_s
        drop gzclose    // zlib.h 1.3.2, gzclose: "Flush all pending output for file, if necessary, close file and deallocate the (de)compression state"
        destroys gzclose_r    // zlib.h 1.3.2, gzclose_r: "Same as gzclose(), but gzclose_r() is only for use when reading"
        destroys gzclose_w    // zlib.h 1.3.2, gzclose_w: "gzclose_w() is only for use when writing or appending"
