//! expect-check-fail: 'abandon other_reset' does not take the representation as its first parameter
//! expect-check-fail: = help: after 'abandon' name a function whose first parameter is what 'Note' wraps

// #3129 (§16.2b.9): the abandonment path is one of the resource's operations.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
        abandon other_reset

fn main:
    print("unreachable")
