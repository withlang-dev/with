//! expect-check-fail: says the callback may run on any thread, but 'note_len' takes no callback
//! expect-check-fail: = help: delete 'callback_thread any'

// #3129 (§16.2b.10): `callback_thread` describes a function that takes a callback.
use c_import("typedef struct note note;\nnote *note_new(void);\nnote *note_from(const int *seed);\nvoid note_free(note *n);\nconst char *note_name(note *n);\nnote *note_peer(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_len
        callback_thread any

fn main:
    print("unreachable")
