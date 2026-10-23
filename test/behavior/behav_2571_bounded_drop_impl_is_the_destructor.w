//! expect-stdout: 111

// #2571 (D154): a `Drop` impl with bounds is the type's destructor as an
// unbounded one is; drop glue runs it at scope end.
use std.builtins.print_i32
type Tag { n: i32 }
var total: i32 = 0
impl Drop for Tag:
    move fn drop(): total = total + self.n
impl Clone for Tag:
    fn clone(): Tag { n: self.n }
type Holder[T: Clone] { v: T }
impl[T: Clone] Drop for Holder[T]:
    move fn drop(): total = total + 100
fn main:
    if true:
        let t = Tag { n: 1 }
        let h = Holder { v: Tag { n: 10 } }
    print_i32(total)
