//! expect-error: c_import symbol 'M_MIN' was omitted

// §16.2: an object macro whose value is a unary operator on a call is
// untranslated like the bare call (C re-evaluates it at each use); a use
// names the omission.
use c_import("int m_runtime(int c);\n#define M_CALL(c) m_runtime(c)\n#define M_MIN ~M_CALL(1)\n")

fn main:
    print(f"{M_MIN}")
