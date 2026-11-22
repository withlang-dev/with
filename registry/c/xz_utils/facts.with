// xz_utils 5.8.4 (liblzma), the version `with get c.xz_utils` pins. Every
// citation is a line of the package's installed headers, include/lzma.
//
// An lzma_stream is initialized in place by any of several coders, and one
// function ends them all. The storage begins zeroed, which is what the
// header requires: base.h line 491, "it must be initialized to
// LZMA_STREAM_INIT", and LZMA_STREAM_INIT (base.h lines 610 to 613) is NULL
// and 0 in every member, LZMA_RESERVED_ENUM being 0 (base.h line 43). An
// initializer that fails leaves nothing to end: base.h line 501, "If the
// initialization function fails, no memory is left allocated that would
// require freeing with lzma_end()".
c facade xz_utils:
    resource Stream wraps lzma_stream
        init lzma_easy_encoder(self), ok LZMA_OK    // lzma/container.h 5.8.4 line 318: "LZMA_OK: Initialization succeeded."
        init lzma_stream_decoder(self), ok LZMA_OK    // lzma/container.h 5.8.4 line 737: "LZMA_OK: Initialization was successful."
        drop lzma_end    // lzma/base.h 5.8.4 line 641: "Free memory allocated for the coder data structures"; line 643: "After lzma_end(strm), strm->internal is guaranteed to be NULL."
