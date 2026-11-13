//! expect-stdout: 7
// A call of an extern function is not a call of a method that has its
// name. `dc_abs` calls libc's `abs`; the method `Dc.abs` calls `dc_abs`.
// The checker took the method's body for the extern's, checked it on
// demand, and reported "`Dc.abs` and `dc_abs` call each other and neither
// declares a return type" (D143). Found through c_import: `dc_free` calling
// libc's `free` beside the generated method `dc.free` (#3292).
type Dc { x: i32 }

extern fn abs(n: i32) -> i32

fn dc_abs(d: &Dc): unsafe { abs(d.x) }

impl Dc:
    fn abs(): dc_abs(self)

fn main:
    let d = Dc { x: -7 }
    print(d.abs())
