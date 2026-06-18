//! expect-error: raw c_import function call requires unsafe context

// #379: a `const char*` parameter is modeled (callable safely with a With str)
// ONLY when the curated libc overlay supplies `cstr_in` evidence for that
// function. `mystrlen` is not a curated symbol, so the blanket
// `const char*`-as-cstring assumption no longer rescues it: it imports with a
// raw surface and the call requires `unsafe`. (Spec §16.3c: an overlay supplies
// evidence, never exemptions; no context reinterpretation / "strlen guessing".)

use c_import("unsigned long mystrlen(const char *s);\n")

fn main:
    let n = mystrlen("hi")
    print("unreachable")
