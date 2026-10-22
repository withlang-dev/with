//! expect-stdout: ran
//! expect-stdout: 4
//! expect-stdout: done

// A module binding of type `Unit` has no storage: a void global traps in
// LLVM (D147's layout assertion, `const __ci_layout_R_check: Unit =
// __ci_layout_R()`, was the first one written). A comptime-evaluated one
// emits nothing; a runtime one runs its initializer before main, for its
// effects, and stores nothing.

@[repr(C)]
pub type P { pub a: u16 = 0, pub b: u16 = 0 }
impl Copy for P

comptime fn layout_check() -> Unit:
    if sizeof[P]() != 4 or offsetof[P](b) != 2: comptime_error("P: layout differs")

const layout_checked: Unit = layout_check()

fn announce() -> Unit:
    print("ran")

let announced: Unit = announce()

fn main:
    print(sizeof[P]())
    print("done")
