//! expect-check-fail: fn 'streamPeek': 'buffer field' stores the slice in Stream's record before the call, and param 0: *const stream s is not a pointer the wrapper may write through
//! expect-check-fail: = help: leave the function raw: an operation that takes the record by a const pointer does not read a buffer the caller sets for the call

// #3129: every contract refusal ends with the spelling that is accepted.
// 'buffer field' on an operation that takes the record by a const pointer.
use c_import("typedef struct stream { const unsigned char *next_in; unsigned int avail_in; int state; const char *label; } stream;\nint streamInit(stream *s);\nint streamEnd(stream *s);\nint streamStep(stream *s, int flush);\nint streamPeek(const stream *s, int flush);\nint plain(int x);\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamPeek
        lend
        buffer field next_in remaining field avail_in

fn main: print(1)
