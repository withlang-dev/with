//! only-on: windows
//! expect-stdout: ok

// #1417: MSVC's `__unaligned` (winnt.h's UNALIGNED, as in wingdi.h's
// `typedef struct tagMETARECORD UNALIGNED *PMETARECORD`) printed into the
// import as `*mut __unaligned struct tagMETARECORD`, which failed to parse
// and stopped every windows.h import. With has no unaligned pointer — a
// `*T` read assumes T's alignment — so the address crosses untyped, as
// `*mut c_void`; reading a Rec through it names the type with a cast.
//
// Windows parses as its gnu target (#1915), where `__unaligned` is the
// target C library's: mingw-w64's _mingw.h, under every system header,
// defines it empty, so the header includes one as windows.h does. (Under
// the Visual Studio SDK fallback it stays MSVC's keyword, the branch above.)

use c_import("#include <stdio.h>\ntypedef struct Rec { unsigned int size; unsigned short kind; } Rec;\ntypedef Rec __unaligned *PREC;\nint rec_play(Rec __unaligned *r, int n);\n")

fn main:
    let p: PREC = null
    let q: *mut c_void = p
    assert(q == null)
    print("ok")
