//! expect-stdout: ok

// #1647 / D65 phase 1: audit:resolution's comparison of a MIR call with
// Sema's answer for it — a callee symbol Sema does not know, a function
// invented from a callable binding's name (#1635), an argument count that
// disagrees with the signature or callable type (#1639's silent case), a
// call node resolved to one signature and lowered to another, a template
// or builtin without its GENERIC_CALL mark. The bodies and the answers are
// planted: the compiler no longer produces these from source.

use MirValidationTests

fn main:
    mir_test_resolution_callees()
    print("ok")
