//! expect-check-fail: applies to an fn item, not a resource
//! expect-check-fail: = help: move 'lend' under the 'fn <name>' item of the function it describes

// #3129 (§16.2b): an fn item's clause under a resource.
use c_import("typedef struct note note;\nnote *note_new(void);\nvoid note_free(note *n);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
        lend

fn main:
    print("unreachable")
