//! expect-check-fail: fn 'reg': param 1: *mut c_void ud is both a buffer or fixed parameter and a callback, userdata, retention or consumption parameter; each parameter has one presented contract (§16.2b.8, §16.2b.9)
//! expect-check-fail: = help: keep one of the two clauses that name this parameter

// #3129 (§16.2b.8, §16.2b.9): one parameter, one presented contract. The
// refusal names both clauses' kinds and says what to do.
use c_import("static inline int reg(int (*f)(void *, int), void *ud, const char *tag) { return f ? 1 : 0; }\n")

c contract lib:
    fn reg
        callback param 0 userdata param 1
        param 1 fixed null

fn main:
    print(1)
