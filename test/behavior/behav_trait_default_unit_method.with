//! expect-stdout: ok

// A trait default method with no return annotation returns Unit. The
// codegen fallback that materialises un-overridden defaults used to alloca
// the void return type directly (LLVM brk in DataLayout::getTypeSizeInBits);
// it must use the dead-i32 slot policy like every other return slot.

trait Greeter:
    fn name(self: &Self) -> str
    fn greet(self: &Self):
        let _ = self.name()

type Quiet { tag: i32 }

impl Greeter for Quiet:
    fn name(self: &Self) -> str: "quiet"

fn main:
    let q = Quiet { tag: 1 }
    q.greet()
    print("ok")
