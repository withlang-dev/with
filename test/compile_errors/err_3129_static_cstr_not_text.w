//! expect-check-fail: 'returns static CStr' describes a NUL-terminated foreign string
//! expect-check-fail: = help: delete the clause, or for a record the library owns write 'returns borrow <Record> from domain <name>'

// #3129 (§16.2b.8): `returns static CStr` describes a returned C string.
use c_import("typedef struct note note;\nenum st { ST_OK = 0, ST_DONE = 1 };\nint note_open(note **out);\nnote *note_new(void);\nvoid note_free(note *n);\nvoid note_reset(note *n);\nconst char *note_msg(note *n);\nint note_len(note *n);\n")

c contract notes:
    fn note_len
        returns static CStr

fn main:
    print("unreachable")
