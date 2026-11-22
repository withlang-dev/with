//! expect-check-fail: fn 'plain': 'buffer field' pairs two fields of the record a lent resource wraps, and 'plain' is no lend of one resource
//! expect-check-fail: = help: state it on an operation whose first parameter receives the resource whose record carries the pointer and its count

// #3129: every contract refusal ends with the spelling that is accepted.
// 'buffer field' on a function that is no operation of a resource.
use c_import("typedef struct stream { const unsigned char *next_in; unsigned int avail_in; int state; const char *label; } stream;\nint streamInit(stream *s);\nint streamEnd(stream *s);\nint streamStep(stream *s, int flush);\nint streamPeek(const stream *s, int flush);\nint plain(int x);\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn plain
        buffer field next_in remaining field avail_in

fn main: print(1)
