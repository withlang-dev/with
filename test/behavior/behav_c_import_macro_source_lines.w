//! expect-stdout: ok

// Recover the whole physical definition from Clang's name offset, including
// CRLF, indentation, continuations, and a final line without a newline.
use c_import("#define FIRST_LINE 11\r\n  #define CONTINUED (20 + \\\r\n 22)\r\n#define IDENTITY(x) \\\n (x)\n#define \\\n NAMED(x) ((x) + 1)\n#define JOIN\\\nED(x) ((x) + 2)\n#de\\\nfine DIRECTIVE 33\n#define LAST_LINE 7")

fn main:
    assert(FIRST_LINE == 11)
    assert(CONTINUED == 42)
    assert(IDENTITY(19) == 19)
    assert(NAMED(19) == 20)
    assert(JOINED(19) == 21)
    assert(DIRECTIVE == 33)
    assert(LAST_LINE == 7)
    print("ok")
