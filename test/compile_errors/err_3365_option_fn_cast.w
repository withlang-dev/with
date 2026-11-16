//! expect-error: an `Option` is not its payload; unwrap it first

// #3365: an `Option` of a function type has no cast to a function type.
// Sema accepted it and MIR refused it as a compiler bug ("unsupported cast
// in MIR").
type D { n: i32 }

unsafe fn run_it(d: *mut D):
    (*d).n = (*d).n + 1

fn main:
    var d = D { n: 1 }
    let stored: Option[extern "C" fn() -> Unit] = Some(unsafe { (run_it as extern "C" fn() -> Unit) })
    unsafe { (stored as unsafe extern "C" fn(*mut D) -> Unit)(&raw mut d) }
    print(f"{d.n}")
