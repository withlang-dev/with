//! expect-check-fail: view `t` may originate from `n`, which no longer lives here (§21.1 Rule 6)

// D51 stage 7 (ruling §32: "Later operations that invalidate the
// underlying resource also invalidate the view through ordinary With
// view-liveness rules"): the borrowed text cannot be used past the note it
// was borrowed from.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_text
        returns borrow CStr from param 0

fn main:
    var t: Option[CStr] = None
    if true:
        let n = Note.note_new(1).unwrap()
        t = n.note_text()
    print(f"{t.is_some()}")
