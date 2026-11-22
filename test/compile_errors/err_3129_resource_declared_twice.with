//! expect-check-fail: resource 'Note' is declared twice
//! expect-check-fail: = help: delete one of the two declarations; a second wrapper of the same record takes another name

// #3129 (§16.2b.3): one resource has one declaration.
use c_import("typedef struct note note;\nenum st { ST_OK = 0, ST_DONE = 1 };\nint note_open(note **out);\nnote *note_new(void);\nvoid note_free(note *n);\nvoid note_reset(note *n);\nconst char *note_msg(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    resource Note wraps *mut note
        from note_new
        drop note_free

fn main:
    print("unreachable")
