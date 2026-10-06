//! expect-stdout: 0 0 true 0 0 0
//! expect-stdout: 0 0

// §16.2b.3: `Representation.zeroed()` is the C record whose bytes are all
// zero (C's `struct rec r = {0};`). It exists on a record every field of
// which has an all-zero value: integers, floats, raw pointers, a C enum (an
// integer), arrays, unions and nested records. A hand-written `@[repr(C)]`
// mirror is a C record too.
use c_import("enum mode { OFF, ON };
struct inner { int depth; char *name; };
struct rec { int count; double scale; int *data; enum mode m; union { int i; float f; } u; char tag[4]; struct inner in; };")

@[repr(C)]
type Pair { left: i64, right: u8 }

fn main:
    let r = rec.zeroed()
    print(f"{r.count} {r.scale} {r.data == null} {r.m} {r.tag[3]} {r.in_.depth}")
    let p = Pair.zeroed()
    print(f"{p.left} {p.right}")
