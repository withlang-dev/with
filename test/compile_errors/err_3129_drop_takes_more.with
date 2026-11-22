//! expect-check-fail: 'drop note_free_with' takes 2 parameters, and Drop has only the representation to pass: param 1: i32 flag is neither fixed nor discarded
//! expect-check-fail: = help: under 'fn note_free_with' write 'param 1 fixed <literal>', or write 'destroys note_free_with' and name another function as 'drop'

// #3129 (§16.2b.3): `drop` names a function of the representation alone.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new
        drop note_free_with

fn main:
    print("unreachable")
