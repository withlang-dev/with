//! expect-check-fail: a profile fn rule states 'lend' or 'destroys'; a clause naming one function's parameters or origins is stated on that fn item in the facade (§16.2b.12)

// D51 stage 11 (§16.2b.12): a profile rule is a name pattern and the
// clause it states; an fn rule states `lend` or `destroys`. A clause that
// names a parameter or an origin describes one function and is written on
// that function's fn item.

c convention local.v1:
    unref: drop *_unref
    errmsg: fn *_errmsg returns borrow CStr from param 0

fn main:
    print("ok")
