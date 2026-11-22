//! expect-stdout: 8 8 8
//! expect-stdout: 0 true
//! expect-stdout: 16 5

// D102, with-abi.md §3 guarantee: `Option[extern "C" fn]`,
// `Option[unsafe extern "C" fn]` and `Option[&T]` are exactly pointer-sized,
// `None` is the null pointer and `Some(p)` is `p`'s address. C records that
// hold a callback depend on it, so this pins it.
@[repr(C)]
type Safe { f: Option[extern "C" fn(i32) -> i32] }

@[repr(C)]
type Unsafe { f: Option[unsafe extern "C" fn(i32) -> i32] }

type Ref ephemeral { r: Option[&i64] }

@[repr(C)]
type Rec { tag: i32, cb: Option[extern "C" fn(i32) -> i32] }

fn five(x: i32): x + 4

fn main:
    print(f"{Safe.size()} {Unsafe.size()} {Ref.size()}")
    // None is the null word.
    let none = Safe { f: None }
    let bits = unsafe { *(&raw const none as *const i64) }
    print(f"{bits} {none.f.is_none()}")
    // Some(p) is p's address, read back through the pointer-sized field.
    let some = Rec { tag: 0, cb: Some(five) }
    let g = some.cb.unwrap()
    print(f"{Rec.size()} {g(1)}")
