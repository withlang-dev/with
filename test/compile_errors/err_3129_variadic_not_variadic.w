//! expect-check-fail: describes a variadic C function, and 'note_len' is not variadic
//! expect-check-fail: = help: delete the 'variadic param …' clause: every parameter of this function is named and typed

// #3129 (§16.2b.5): a variadic clause on a function that is not variadic.
use c_import("typedef struct note note;\nenum st { ST_OK = 0, ST_DONE = 1 };\nint note_open(note **out);\nnote *note_new(void);\nvoid note_free(note *n);\nvoid note_reset(note *n);\nconst char *note_msg(note *n);\nint note_len(note *n);\n")

c contract notes:
    fn note_len
        variadic param 1 selected by param n:
            case ST_OK: c_long

fn main:
    print("unreachable")
