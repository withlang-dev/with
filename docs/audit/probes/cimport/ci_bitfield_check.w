use c_import("struct BITS { unsigned int a : 3; unsigned int b : 5; }; struct OUTER { struct BITS b; int x; };")
fn main:
    print("bitfield import ok")
