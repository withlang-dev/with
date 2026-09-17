//! expect-stdout: ok

// Whitespace, grouping, expression nesting, and aliases must preserve an
// omitted macro dependency without poisoning an import that never uses it.
use c_import("#define ATTRIBUTE(x) __attribute__((deprecated))\n#define SPACED ATTRIBUTE (4.0)\n#define GROUPED (ATTRIBUTE(4.0))\n#define NESTED (1 + ATTRIBUTE(4.0))\n#define CHAIN GROUPED\n")

fn main: print("ok")
