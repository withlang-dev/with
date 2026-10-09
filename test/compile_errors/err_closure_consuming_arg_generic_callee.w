//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): a generic callee's specialization is the body the proof
// reads. It was never consulted, so a generic callee ran a consuming
// closure twice (the second call returned the move-blanked capture).
// A List capture, not a str: a str capture is copied (D111).
fn twice[T](f: fn() -> T) -> T:
    let a = f()
    f()

fn main:
    let s: List[i32] = [1, 2, 3]
    print(twice(() => s).len())
