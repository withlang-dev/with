//! expect-check-fail: a foreign-state domain is the origin of borrowed memory that no resource owns
//! expect-check-fail: = help: write 'returns borrow Note from param N', with N the parameter that receives the resource it is a view of

// #3129 (§16.2b.6, §16.2b.7): a borrowed resource is a view of a parameter's resource.
use c_import("typedef struct note note;\nnote *note_new(void);\nnote *note_from(const int *seed);\nvoid note_free(note *n);\nconst char *note_name(note *n);\nnote *note_peer(note *n);\nint note_len(note *n);\n")

c contract notes:
    domain peers process
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_peer
        returns borrow Note from domain peers

fn main:
    print("unreachable")
