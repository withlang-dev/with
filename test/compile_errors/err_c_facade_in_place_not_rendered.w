//! expect-check-fail: is an in-place resource (init/preinit); the compiler does not render in-place resources yet

// D51 §16.2b.3 stage 4a renders pointer and by-value resources; an in-place
// resource (`init`, stage 4b) is verified but not rendered, and that is a
// loud diagnostic at the resource — never a placeholder type without Drop.

use c_import("typedef struct { int state; } z_stream;
int inflateInit(z_stream* s);
int inflateEnd(z_stream* s);
")

c facade zlib:
    resource InflateStream wraps z_stream
        init inflateInit
        drop inflateEnd

fn main:
    print("ok")
