//! expect-check-fail: with no 'drop' and no 'destroys'
//! expect-check-fail: = help: add 'drop <fn>', naming the C function that releases what the producer returns

// #3129 (§16.2b.3): a producer needs a destruction contract.
use c_import("typedef struct note note;\nenum st { ST_OK = 0 };\nnote *note_new(void);\nint note_open(note **out);\nvoid note_free(note *n);\nvoid note_free_with(note *n, int flag);\nvoid note_write(note *n, const char *src, unsigned long len);\nvoid note_reset(note *n);\nvoid note_reset_to(note *n, int v);\nconst char *last_msg(int code);\nvoid other_reset(int v);\n")

c contract notes:
    resource Note wraps *mut note
        from note_new

fn main:
    print("unreachable")
