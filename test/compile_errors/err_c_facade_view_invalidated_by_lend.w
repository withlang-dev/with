//! expect-check-fail: view `t` borrows from `n`, which `note_fill` may have invalidated (§16.2b.7)
//! expect-check-fail: state `preserves param 0` on fn note_fill in facade notes if it leaves that storage valid, or copy `t` out (`to_owned()`) before the call

// D51 stage 7 (ruling §38: "Unknown effect means invalidate"): a lend of
// the note that states no preservation invalidates the text borrowed from
// it; the next use names the call and the clause to add.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_text
        returns borrow CStr from param 0
    fn note_fill
        lend

fn main:
    let n = Note.note_new(3).unwrap()
    let t = n.note_text().unwrap()
    let _ = n.note_fill('x', 4)
    print(f"{t.len()}")
