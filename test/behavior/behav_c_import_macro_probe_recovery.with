//! expect-stdout: ok

// Context-dependent initializer lists and unresolved expressions have no
// standalone type. Clang's recovery declarations must not become With globals.
// Valid siblings, including a typed compound literal, remain usable.
use c_import("typedef struct Pair { int a; int b; } Pair;\n#define END { 0, (void *)0 }\n#define DESIGNATED { .a = 3, .b = 4 }\n#define UNKNOWN (missing_name + 1)\n#define PAIR ((Pair){ 20, 22 })\n#define ANSWER (20 + 22)\n")

fn main:
    assert(ANSWER == 42)
    assert(PAIR.a + PAIR.b == 42)
    print("ok")
