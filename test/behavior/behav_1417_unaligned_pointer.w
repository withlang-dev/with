//! only-on: windows
//! expect-stdout: ok

// #1417: MSVC's `__unaligned` (winnt.h's UNALIGNED, as in wingdi.h's
// `typedef struct tagMETARECORD UNALIGNED *PMETARECORD`) printed into the
// import as `*mut __unaligned struct tagMETARECORD`, which failed to parse
// and stopped every windows.h import. With has no unaligned pointer — a
// `*T` read assumes T's alignment — so the address crosses untyped, as
// `*mut c_void`; reading a Rec through it names the type with a cast.

use c_import("typedef struct Rec { unsigned int size; unsigned short kind; } Rec;\ntypedef Rec __unaligned *PREC;\nint rec_play(Rec __unaligned *r, int n);\n")

fn main:
    let p: PREC = null
    let q: *mut c_void = p
    assert(q == null)
    print("ok")
