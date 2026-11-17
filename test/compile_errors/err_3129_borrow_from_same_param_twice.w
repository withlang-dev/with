//! expect-check-fail: names one parameter twice; a borrow from one parameter is written
//! expect-check-fail: = help: write 'from param 0'

// #3129 (§16.2b.6): a borrow from one parameter names it once.
use c_import("typedef struct note note;\nnote *note_new(void);\nnote *note_from(const int *seed);\nvoid note_free(note *n);\nconst char *note_name(note *n);\nnote *note_peer(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_name
        returns borrow CStr from params 0, 0

fn main:
    print("unreachable")
