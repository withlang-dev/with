//! expect-check-fail: fn 'streamStep': 'buffer field state' names a field of type i32, not a pointer to bytes
//! expect-check-fail: = help: after 'buffer field' name the field that points at the bytes; its count follows 'remaining field'

// #3129: every contract refusal ends with the spelling that is accepted.
// 'buffer field' naming a field that is not a pointer to bytes.
use c_import("typedef struct stream { const unsigned char *next_in; unsigned int avail_in; int state; const char *label; } stream;\nint streamInit(stream *s);\nint streamEnd(stream *s);\nint streamStep(stream *s, int flush);\nint streamPeek(const stream *s, int flush);\nint plain(int x);\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamStep
        lend
        buffer field state remaining field avail_in

fn main: print(1)
