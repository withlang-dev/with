//! expect-stdout: ok

// #1639 / D65: the typed MIR validator rejects a call whose `const fn`
// callee is no function Sema knows — no signature, no generic template, no
// builtin, no body in the module — and no intrinsic mark. The MIR is built
// by hand: the source that once produced it (`let r = c.run; r(21)`, #1635)
// now lowers through the callable binding.

use MirValidationTests

fn main:
    mir_test_unknown_callee()
    print("ok")
