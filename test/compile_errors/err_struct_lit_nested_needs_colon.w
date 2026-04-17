//! expect-check-fail: expected identifier
// Before this test was added, the parser would infinite-loop inside
// parse_struct_literal when a field position held a nested struct
// literal where the enclosing literal expected `ident: value` form.
// `expect_ident` emits an error and returns 0 WITHOUT advancing the
// token stream, so the while loop re-ran with the same L_BRACE token
// forever. Under -O0 the compiler-generated alloca() for method-call
// receivers accumulates per iteration, so the process eventually
// SIGSEGVs on the stack guard page instead of printing an error.
//
// Exit criterion for the fix: this file exits 1 with "expected
// identifier" in the diagnostics, not SIGSEGV.
fn main:
    let g = Outer { Inner { x: 1 } }
