//! expect-stdout: ok

// #1442: the MIR validator's type for an undeclared payload place of a user
// generic enum instance is the declared payload, never the Option-shaped guess
// of its type argument. The MIR is built by hand: source lowering now declares
// payload places with their substituted type (#1441).

use MirValidationTests

fn main:
    mir_test_generic_payload_not_guessed()
    print("ok")
