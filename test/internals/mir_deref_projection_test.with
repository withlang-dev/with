//! expect-stdout: ok

// The typed MIR validator rejects a dereference of a value that is not a
// reference or a pointer. `for d in deps[k]` dereferenced the element place
// `_xs[_i]` (its Sema type is the view `&List[i32]`, its place the List
// itself), declared the inner List, and `--validate-all` said ok. The MIR is
// built by hand: the lowering now decides by the place's type.

use MirValidationTests

fn main:
    mir_test_deref_projection()
    print("ok")
