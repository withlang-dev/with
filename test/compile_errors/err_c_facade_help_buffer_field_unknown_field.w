//! expect-check-fail: fn 'streamStep': 'buffer field nope remaining field avail_in' names 'nope', which is no field of the record Stream wraps
//! expect-check-fail: = help: name the pointer field and the count field as the header declares them

// #3129: every contract refusal ends with the spelling that is accepted.
// 'buffer field' naming a field the record does not have.
use c_import("typedef struct stream { const unsigned char *next_in; unsigned int avail_in; int state; const char *label; } stream;\nint streamInit(stream *s);\nint streamEnd(stream *s);\nint streamStep(stream *s, int flush);\nint streamPeek(const stream *s, int flush);\nint plain(int x);\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamStep
        lend
        buffer field nope remaining field avail_in

fn main: print(1)
