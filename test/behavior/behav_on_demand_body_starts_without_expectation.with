//! expect-stdout: big
//! expect-stdout: done

// A body checked on demand (D43: a callee with an inferred return is
// typed before its caller) starts with no expectation of its own. The
// caller's leaked into it: a top-level initializer's expected type
// reached the demanded body through the call argument naming it, and an
// unsafe fn's brace body — one `if` under the unsafe node, which
// propagates an expectation — was refused as a value if without else
// (stc's cstr_drop in its test programs).
pub type S { pub size: i32 }
pub type Slot { pub f: unsafe fn(*const S) -> Unit }
pub type Table { pub slot: Slot }

pub unsafe fn c_drop(p: *const S) {
    if ((*p).size >= 128) {
        print("big")
    }

}

fn with_drop(f: unsafe fn(*const S) -> Unit) -> Slot: Slot { f: f }

let TABLE: Table = Table { slot: with_drop(c_drop) }

fn main:
    let s = S { size: 200 }
    unsafe { (TABLE.slot.f)(&raw const s) }
    print("done")
