//! expect-check-fail: names the resource's producer, initializer, drop or destroyer; the abandonment path
//! expect-check-fail: = help: after 'abandon' name the operation that undoes the callback setup and leaves the resource usable

// #3129 (§16.2b.9): the abandonment path leaves the resource live.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free
        abandon note_free

fn main:
    print("unreachable")
