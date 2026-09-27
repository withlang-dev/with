//! expect-stdout: addr: 42
//! expect-stdout: i32 address: true
//! expect-stdout: f64 through the pointer: 2.5
//! expect-stdout: mut address: true
//! expect-stdout: struct through the pointer: 2
//! expect-stdout: pointer view value: true
//! expect-stdout: widened value: 42
//! expect-stdout: ok

// #1777 (§16.11, D22 §6.1): a shared reference `&T` cast to `*const T` or
// `*mut T` is the reference relabeled as a raw pointer — its address. The
// cast lowering materialized a scalar pointee instead (read the `T`, then
// turned its value into an address), so `unsafe { *p }` faulted; the
// facade's `ud as *const U` did the same in safe code. A view whose pointee
// is the demanded pointer still supplies that pointer (`&*mut u8` as
// `*mut u8`, D22 §6.1), and a non-pointer cast target still materializes
// (`r as i64`).

type Pt { x: i32, y: i32 }
impl Copy for Pt

fn addr(r: &i32) -> *const i32: r as *const i32
fn addr_f(r: &f64) -> *const f64: r as *const f64
fn addr_mut(r: &i32) -> *mut i32: r as *mut i32
fn addr_pt(r: &Pt) -> *const Pt: r as *const Pt
fn pointer_of(r: &*mut u8) -> *mut u8: r as *mut u8
fn widened(r: &i32) -> i64: r as i64

fn main:
    let x = 42
    let p = addr(x)
    print(f"addr: {unsafe { *p }}")
    print(f"i32 address: {p as usize == (&raw const x) as usize}")
    let f = 2.5
    let pf = addr_f(f)
    print(f"f64 through the pointer: {unsafe { *pf }}")
    print(f"mut address: {addr_mut(x) as usize == (&raw const x) as usize}")
    let pt = Pt { x: 1, y: 2 }
    let pp = addr_pt(pt)
    print(f"struct through the pointer: {unsafe { (*pp).y }}")
    let raw = (&raw const x) as *mut u8
    print(f"pointer view value: {pointer_of(raw) as usize == raw as usize}")
    print(f"widened value: {widened(x)}")
    print("ok")
