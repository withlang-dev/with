//! expect-check-fail: one state has one scope
//! expect-check-fail: = help: use 'process' here, or name a second domain for the other scope

// #3129 (§16.2b.7): one domain has one scope across contracts.
use c_import("typedef struct note note;\nnote *note_new(void);\nnote *note_from(const int *seed);\nvoid note_free(note *n);\nconst char *note_name(note *n);\nnote *note_peer(note *n);\nint note_len(note *n);\n")

c contract notes:
    domain peers process

c contract more_notes:
    domain peers thread
    fn note_len
        lend

fn main:
    print("unreachable")
