//! expect-check-fail: c_import symbol 'take_cb1024' was omitted: untranslatable: vector of a lane type With has no vector of
// #1024: a C callback whose parameter c_import cannot translate (a vector
// of 128-bit lanes) imported with `i32` in that slot, a wrong ABI and no
// diagnostic. The function taking it is now omitted and says why.
use c_import("err_1024_callback_param_untranslatable.h")

fn main:
    unsafe { take_cb1024(null) }
