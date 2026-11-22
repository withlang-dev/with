//! expect-check-fail: 'ok' lists 'ST_OK' twice
//! expect-check-fail: = help: delete one 'ST_OK'

// #3129 (§16.2b.4): a success status is listed once.
use c_import("typedef struct note note;\nenum st { ST_OK = 0, ST_DONE = 1 };\nint note_open(note **out);\nnote *note_new(void);\nvoid note_free(note *n);\nvoid note_reset(note *n);\nconst char *note_msg(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_open(out param 0)
        ok ST_OK, ST_OK
        drop note_free

fn main:
    print("unreachable")
