//! expect-check-fail: unknown method 'note_open' for type 'Note'
//! expect-check-fail: = help: did you mean `open`?
// A facade presents `note_open` on `Note` as `Note.open`; writing the C
// name names the presented one (#3521: `Stream.lzma_easy_encoder` gave no
// hint that it is `Stream.easy_encoder`).
use c_import("typedef struct note note;\nnote *note_open(int n);\nvoid note_close(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_open
        drop note_close

fn main:
    let n = Note.note_open(1)
    print("unreachable")
