//! expect-check-fail: 'abandon' is stated twice; a resource has one abandonment path
//! expect-check-fail: = help: delete one of the two 'abandon' clauses

// #3129 (§16.2b.9): one abandonment path.
use c_import("typedef struct note note;\nenum st { ST_OK = 0, ST_DONE = 1 };\nint note_open(note **out);\nnote *note_new(void);\nvoid note_free(note *n);\nvoid note_reset(note *n);\nconst char *note_msg(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
        abandon note_reset
        abandon note_reset

fn main:
    print("unreachable")
