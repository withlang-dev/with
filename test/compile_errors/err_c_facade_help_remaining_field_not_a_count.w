//! expect-check-fail: fn 'streamStep': 'remaining field label' names a field of type *const c_char, not an integer count
//! expect-check-fail: = help: after 'remaining field' name the integer field that holds how many bytes are left

// #3129: every contract refusal ends with the spelling that is accepted.
// 'remaining field' naming a field that is not an integer.
use c_import("typedef struct stream { const unsigned char *next_in; unsigned int avail_in; int state; const char *label; } stream;\nint streamInit(stream *s);\nint streamEnd(stream *s);\nint streamStep(stream *s, int flush);\nint streamPeek(const stream *s, int flush);\nint plain(int x);\n")

c contract st:
    resource Stream wraps stream
        init streamInit(self)
        drop streamEnd
    fn streamStep
        lend
        buffer field next_in remaining field label

fn main: print(1)
