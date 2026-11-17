//! expect-check-fail: unknown resource 'Book'
//! expect-check-fail: = help: declare it above this item ('resource Book wraps *mut T'), or name a resource the contract declares

// #3129 (§16.2b.6): a borrowed resource is one the contract declares.
use c_import("typedef struct note note;\nnote *note_new(void);\nnote *note_from(const int *seed);\nvoid note_free(note *n);\nconst char *note_name(note *n);\nnote *note_peer(note *n);\nint note_len(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
    fn note_peer
        returns borrow Book from param 0

fn main:
    print("unreachable")
