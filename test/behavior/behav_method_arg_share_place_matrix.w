//! expect-stdout: ok

// D5 (superseded — docs/meetings/2026-07-05-D5-historical-share-place-free-parameter-design-superseded.md): a parameter's ownership mode is
// DECLARED, never inferred from the body's effects. `&T` borrows (the plain
// call spelling auto-refs), plain `T` is owned by the callee, and mutation
// that must reach the caller threads the value take-and-return (D21). The
// old matrix asserted effects-inferred share-place write-through on plain
// parameters; that behavior is gone by ruling.

type Payload { id: i32 }
type Holder { value: Payload }
type Runner {}

impl Runner:
    fn read(value: &Payload): value.id
    fn bump(value: Payload) -> Payload: Payload { id: value.id + 1 }
    fn recursive_read(value: &Payload, depth: i32) -> i32:
        if depth == 0: value.id
        else: self.recursive_read(value, depth - 1)
    fn take(value: Payload) -> Payload: value
    fn generic_take[T](value: T) -> T: value

fn main:
    let runner = Runner {}

    // A declared borrow: plain call spelling, caller retains the value.
    let read_value = Payload { id: 7 }
    assert(runner.read(read_value) == 7)
    assert(read_value.id == 7)

    // Mutation reaches the caller by threading, not by hidden write-through.
    var written = Payload { id: 10 }
    written = runner.bump(written)
    written = runner.bump(written)
    assert(written.id == 12)

    // Borrows pass onward as views, including recursively.
    let recursive = Payload { id: 20 }
    assert(runner.recursive_read(recursive, 3) == 20)
    assert(recursive.id == 20)

    // Field places borrow the same way.
    let holder = Holder { value: Payload { id: 30 } }
    assert(runner.read(holder.value) == 30)
    assert(holder.value.id == 30)

    // (Generic &T parameters cannot yet infer T from an auto-ref arg;
    // generic borrows join the matrix when that inference lands.)

    // Plain T is owned by the callee; values transfer without ceremony.
    let owned = Payload { id: 60 }
    let taken = runner.take(owned)
    assert(taken.id == 60)

    let generic_owned = Payload { id: 70 }
    let generic_taken = runner.generic_take(generic_owned)
    assert(generic_taken.id == 70)

    print("ok")
