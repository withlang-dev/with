//! expect-error: an `extern fn` cannot return an array

// #1975 (C11 6.7.6.3p1): an `extern fn` declaration names a C function,
// and no C function returns an array — the same rule as the
// `extern "C" fn` type (err_1975_extern_fn_type_returns_array.w).
extern fn get_pair() -> [u16; 2]

fn main:
    print("x")
