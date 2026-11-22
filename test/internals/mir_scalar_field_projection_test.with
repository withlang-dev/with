//! expect-stdout: ok

// #1464: the typed MIR validator rejects a field projection of a scalar and
// a fiber intrinsic whose task operand is not a Task handle. The MIR is built
// by hand: the lowering that produced both (an unannotated `async fn`'s call
// typed as the awaited value) now types the call `Task[T]`.

use MirValidationTests

fn main:
    mir_test_scalar_field_projection()
    mir_test_task_operand()
    print("ok")
