//! expect-check-fail: view 't' may outlive its origin 'n'

// D51 stage 7 (ruling §32): dropping the note while its borrowed text is
// still used is refused.
use c_import("../behavior/c_facade_text.h")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_text
        returns borrow CStr from param 0

fn main:
    let n = Note.note_new(1).unwrap()
    let t = n.note_text().unwrap()
    drop(n)
    print(f"{t.len()}")
