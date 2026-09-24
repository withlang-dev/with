//! expect-check-fail: view 'v' may outlive its origin 'd'

// D51 stage 7 (ruling §42: "The owned resource may expose a borrowed CStr
// view"): the view of caller-owned text does not outlive the resource that
// releases it.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    resource NoteText wraps *mut i8
        from strdup
        drop free

fn main:
    let d = NoteText.strdup("dup").unwrap()
    let v = d.as_cstr()
    drop(d)
    print(f"{v.len()}")
