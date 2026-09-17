//! expect-stdout: ok

// Failed function-macro translations must not authorize dependent globals.
// Cover attribute/variadic omissions, their function aliases, and every
// successful function-macro emission branch in the same import.
use c_import("#define ATTRIBUTE(x) __attribute__((deprecated))\n#define ANNOTATION ATTRIBUTE(4.0)\n#define ATTRIBUTE_ALIAS ATTRIBUTE\n#define ALIASED_ANNOTATION ATTRIBUTE_ALIAS(4.0)\n#define VARIADIC(fmt, ...) printf(fmt, __VA_ARGS__)\n#define UNUSED_CALL VARIADIC(0, 1)\n#define EMPTY(x)\n#define IDENTITY(x) (x)\n#define STRINGIFY(x) #x\n#define ADD(a, b) ((a) + (b))\n#define ANSWER ADD(20, 22)\n")

fn main:
    EMPTY(1)
    assert(IDENTITY(7) == 7)
    assert(ANSWER == 42)
    print("ok")
