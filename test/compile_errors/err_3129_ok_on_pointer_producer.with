//! expect-check-fail: names a status, but no producer returns one to compare it with
//! expect-check-fail: = help: delete 'ok': it applies to a producer that returns an integer status and stores the resource through an out parameter

// #3129 (§16.2b.4): `ok` reads an integer status.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        ok ST_OK
        drop note_free

fn main:
    print("unreachable")
