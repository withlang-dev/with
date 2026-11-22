//! expect-stdout: ok

// A parameter or a local shadows every global of its name, in every module.
// A private top-level `let ptr` here used to break each imported function
// that has a `ptr` parameter ("symbol 'ptr' is not visible from this
// module"): check_ident found the parameter, then looked the name up again
// and found this module's global. A stdlib function with a parameter named
// like any user global was enough.
use param_named_like_a_global

let ptr: i32 = 7

fn main:
    assert(Holder.make(1).v == 1 and plain(1) == 2 and Holder.make(1).add(1) == 2)
    assert(local_too() == 42 and ptr == 7)
    print("ok")
