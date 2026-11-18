//! expect-check-fail: fn 'reg': nullable param 2: *const c_char tag; on a callback contract, nullability is rendered for the callback of a 'callback param N userdata param M' pairing that C uses during the call only
//! expect-check-fail: = help: delete the 'nullable' clause, or name the callback parameter of the pairing

// #3129 (§16.2b.8, §16.2b.9): on a callback item 'nullable' speaks of the
// paired callback; a raw pointer parameter accepts null as C declares it.
use c_import("static inline int reg(int (*f)(void *, int), void *ud, const char *tag) { return f ? 1 : 0; }\n")

c contract lib:
    fn reg
        callback param 0 userdata param 1
        nullable param 2

fn main:
    print(1)
