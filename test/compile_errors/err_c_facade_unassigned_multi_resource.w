//! expect-check-fail: fn 'z_reset': param 0: *mut z_stream s receives a representation several resources wrap ('InflateStream', 'DeflateStream'); an operation is callable through a resource only after the facade assigns it, so 'z_reset' is not presented on any of them (§16.2b.3)

// D51 stage 8 (ruling §14, §53): "When a foreign representation maps to
// multiple modeled resources, an operation is callable through a modeled
// resource only after resource assignment is known. An unassigned
// `z_stream *` operation is rejected on both modeled resources, with a
// diagnostic naming the candidates." The fix-it names the `of` clause.

use c_import("typedef struct { int state; } z_stream;
int inflateInit(z_stream* s);
int deflateInit(z_stream* s, int level);
int z_reset(z_stream* s);
void inflateEnd(z_stream* s);
void deflateEnd(z_stream* s);
")

c facade zlib:
    resource InflateStream wraps z_stream
        init inflateInit(self)
        drop inflateEnd
    resource DeflateStream wraps z_stream
        init deflateInit(self)
        drop deflateEnd
    fn z_reset

fn main:
    print("x")
