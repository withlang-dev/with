//! expect-check-fail: fn 'note_init': an initializer takes only what the resource passes it; a fixed argument on 'note_init' is not modeled (§16.2b.11)
//! expect-check-fail: = help: delete 'param N fixed …' under 'fn note_init'

// #3129 (§16.2b.11): an initializer takes only what the resource passes
// it. A drop or a destroyer may fix its other parameters since D209.
use c_import("typedef struct { int n; } note;\nint note_init(note *n, int flag);\nvoid note_end(note *n);\n")

c contract notes:
    resource Note wraps note
        init note_init(self)
        drop note_end
    fn note_init
        param flag fixed 0

fn main:
    print("unreachable")
