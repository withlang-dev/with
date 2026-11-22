//! expect-stdout: 7

// D29 precedence at call position: a lexical CALLABLE binding wins over a
// same-named module-level fn from another module (same-module shadowing is
// rejected outright, so only the cross-module case exists). The local must
// actually EXECUTE — a silent rebind to the global printed 100 here in an
// earlier attempt at a wider shadow rule.
use aux_tag

fn main:
    let tag = () => 7
    print(f"{tag()}")
