//! expect-stdout: ok

// Constant invocations remain usable; unused runtime invocations must not
// become once-only global initializers, even through an emitted macro.
use c_import("int tick(void);\n#define TICK tick()\n#define SPACED_TICK tick ()\n#define WRAP(x) tick()\n#define WRAPPED WRAP(0)\n#define SPACED_WRAPPED WRAP (0)\n#define ADD(a, b) ((a) + (b))\n#define ANSWER ADD (20, 22)\n")

fn main:
    assert(ANSWER == 42)
    print("ok")
