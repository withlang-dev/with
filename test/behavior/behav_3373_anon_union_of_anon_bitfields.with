//! expect-stdout: 9

// #3373: a C11 anonymous union whose anonymous member is a record of
// bitfields (winnt.h's `union { DWORD Flags; struct { DWORD a : 1; … }; }`).
// The bitfield record imports opaque (§16.9) and so must the union that holds
// it by value, and the record that holds the union. The predicate that asks
// looked only at named fields, so the union was declared with an opaque
// member, which Sema refuses: importing any header that includes windows.h
// (bzlib.h) failed, in declarations the program never names.
use c_import("typedef struct Policy { union { unsigned Flags; struct { unsigned a : 1; unsigned b : 1; }; }; } Policy;\ntypedef struct Wide { union { unsigned Flags; struct { unsigned a : 1; unsigned b : 1; } bits; } u; } Wide;\nstatic inline int nine(void) { return 9; }\n")

fn main:
    print(nine())
