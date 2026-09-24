//! expect-check-fail: view `hit` may originate from `s`, which no longer lives here (§21.1 Rule 6)

// D51 stage 7 (ruling §31: the origin of strchr's result is the string it
// was lent, `returns borrow CStr from param 0`): the text cannot outlive
// the `str` it points into.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    fn strchr
        returns borrow CStr from param 0

fn main:
    var hit: Option[CStr] = None
    if true:
        let s = "hello".to_owned()
        hit = strchr(s, 'l')
    print(f"{hit.is_some()}")
