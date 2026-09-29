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
    // §16.11: a raw c_import function with a pointer parameter is unsafe to
    // call, so as a value it is an unsafe callable and binds only to an
    // `unsafe extern "C" fn` type (#1829); `with_issue546_noop` has no
    // pointer contract and stays a safe callable.
    let _identity: unsafe extern "C" fn(*mut c_void) -> *mut c_void = with_issue546_identity
    print("ok")
