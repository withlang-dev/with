//! expect-check-fail: a destroying operation is not callable as a lend
//! expect-check-fail: = help: delete the 'lend' line under

// #3129 (§31.8.2): a destroyer's fn item does not say `lend`.
use c_import("typedef struct note note;\nenum st { ST_OK = 0, ST_DONE = 1 };\nint note_open(note **out);\nnote *note_new(void);\nvoid note_free(note *n);\nvoid note_reset(note *n);\nconst char *note_msg(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_free
        lend

fn main:
    print("unreachable")
