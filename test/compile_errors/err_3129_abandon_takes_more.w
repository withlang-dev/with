//! expect-check-fail: the abandonment path has only the representation to pass: param 1: i32 v is neither fixed nor discarded
//! expect-check-fail: = help: fix or discard it on the function's own item

// #3129 (§16.2b.9): generated cleanup passes the abandonment path nothing else.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
        abandon note_reset_to

fn main:
    print("unreachable")
