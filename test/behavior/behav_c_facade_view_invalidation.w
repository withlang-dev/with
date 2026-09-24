//! expect-stdout: before: note-3 6
//! expect-stdout: after fill: xxxx
//! expect-stdout: child: 3
//! expect-stdout: ok

// D51 stage 7 (ruling §38: "Unknown effect means invalidate … A facade may
// state `preserves param 0`"): a text view stays usable across `note_len`
// (declared `preserves param 0`) and dies at `note_fill`, which states
// nothing — so the program reads it before, and borrows again after. A
// dependent child (`Twin`, produced from the note) is a resource, not a
// view of the note's memory: `note_fill` does not invalidate it (§27 is
// lifetime). The refused spelling is err_c_facade_view_invalidated_by_lend.

use c_import("c_facade_text.h")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    resource Twin wraps *mut twin
        from twin_new
        drop twin_free
    fn twin_id
        lend
    fn note_text
        returns borrow CStr from param 0
    fn note_len
        lend
        preserves param 0
    fn note_fill
        lend
    fn note_id
        lend

fn main:
    let n = Note.new(3).unwrap()
    let child = Twin.new(n).unwrap()
    let t = n.text().unwrap()
    let len = n.len()
    print(f"before: {t.to_str().unwrap()} {len}")
    let _ = n.fill('x', 4)
    print(f"after fill: {n.text().unwrap().to_str().unwrap()}")
    print(f"child: {child.id()}")
    print("ok")
