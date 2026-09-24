//! expect-stdout: text: note-7 len=6 owned=note-7
//! expect-stdout: empty: true
//! expect-stdout: dup: dup 3
//! expect-stdout: lossy: 3
//! expect-stdout: ok

// D51 stage 7 (ruling §32, §41, §42; spec §16.2b.8): `returns borrow CStr
// from param 0` on `note_text(note *)` renders `Note.text() ->
// Option[CStr]` — the nullable foreign string is an Option of the borrowed
// text, a view of the note that NULL turns into None. Conversion is
// explicit: `to_str` validates (a `&str` over the same bytes), `to_owned`
// copies. Caller-owned text is a resource (`strdup` → `free`) exposing a
// borrowed `as_cstr()` view; the foreign allocator pairing is untouched.

use c_import("c_facade_text.h")

c facade notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    resource NoteText wraps *mut i8
        from strdup
        drop free
    fn note_id
        lend
    fn note_text
        returns borrow CStr from param 0
    fn note_len
        lend
        preserves param 0

fn main:
    let n = Note.new(7).unwrap()
    let t = n.text().unwrap()
    print(f"text: {t.to_str().unwrap()} len={t.len()} owned={t.to_owned()}")
    let empty = Note.new(-1).unwrap()
    print(f"empty: {empty.text().is_none()}")
    let d = NoteText.strdup("dup").unwrap()
    let v = d.as_cstr()
    print(f"dup: {v.to_str().unwrap()} {v.len()}")
    print(f"lossy: {v.to_str_lossy().len()}")
    print("ok")
