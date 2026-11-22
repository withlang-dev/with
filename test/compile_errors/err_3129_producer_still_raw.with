//! expect-check-fail: producer 'note_from' is still a raw call after the facade covers its return
//! expect-check-fail: = help: add 'fn note_from' with a clause for each pointer parameter

// #3129 (§16.2b.5): a producer with an undescribed pointer parameter.
use c_import("typedef struct note note;\nnote *note_new(void);\nnote *note_from(const int *seed);\nvoid note_free(note *n);\nconst char *note_name(note *n);\nnote *note_peer(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_from
        drop note_free

fn main:
    print("unreachable")
