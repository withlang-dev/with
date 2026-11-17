//! expect-check-fail: a value record is flat
//! expect-check-fail: = help: declare the record a resource ('resource Name wraps *mut T' with its producer and 'drop'), or leave the function raw

// #3129 (§16.2b.5): a record that holds a pointer is not a value record; the
// refusal says what it can be.
use c_import("typedef struct span { const char *at; int n; } span;\nstatic inline int span_len(const span *s) { return s->n; }\n")

c contract spans:
    fn span_len
        reads param s

fn main:
    print("unreachable")
