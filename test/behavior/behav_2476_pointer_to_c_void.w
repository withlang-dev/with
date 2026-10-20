//! expect-stdout: let true
//! expect-stdout: assign true
//! expect-stdout: return true
//! expect-stdout: argument true
//! expect-stdout: field true
//! expect-stdout: const true

// §16.3b: a raw pointer converts to a pointer to `c_void` wherever a value
// meets its type (a C `void*` takes any object pointer). Sema accepted the
// conversion everywhere, but the MIR validator refused the let, the
// assignment and the return (an internal compiler error, #2476) while the
// argument and the field initializer passed.

type Rec { size: i32 }

type Holder { erased: *mut c_void }

fn erase(p: *mut Rec) -> *mut c_void: p

fn is_null(v: *mut c_void): v == null

fn main:
    var rec = Rec { size: 4 }
    let p: *mut Rec = &raw mut rec
    let q: *mut c_void = p
    print(f"let {q == p as *mut c_void}")
    var r: *mut c_void = null
    r = p
    print(f"assign {r == q}")
    print(f"return {erase(p) == q}")
    print(f"argument {not is_null(p)}")
    let h = Holder { erased: p }
    print(f"field {h.erased == q}")
    let c: *const Rec = p
    let cv: *const c_void = c
    print(f"const {cv == q as *const c_void}")
