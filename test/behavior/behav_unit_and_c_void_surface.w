//! expect-stdout: ok

use c_import("void with_issue546_noop(void);\nvoid *with_issue546_identity(void *p);\n")

fn explicit_unit_return() -> Unit:
    return

fn accepts_unit(value: Unit):
    let _x = value

fn accepts_c_void_ptr(ptr: *mut c_void):
    assert(ptr == null)

fn main:
    accepts_unit(explicit_unit_return())
    accepts_c_void_ptr(null as *mut c_void)
    let _noop: extern "C" fn() -> Unit = with_issue546_noop
    let _identity: extern "C" fn(*mut c_void) -> *mut c_void = with_issue546_identity
    print("ok")
