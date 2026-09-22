//! expect-check-fail: 'preinit' constructs storage for an 'init' operation; state 'init <fn>(self)'

// D51 ruling §13.1 stage 4b: pre-initialization is the first state of an
// in-place resource; without an `init` there is nothing for the storage to
// become live through.

use c_import("typedef struct { int state; } z_stream;
z_stream z_storage(void);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        preinit z_storage
        drop z_end

fn main:
    print("ok")
