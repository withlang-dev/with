//! expect-check-fail: is bound by 'fixed' and cannot also be a buffer or its length
//! expect-check-fail: = help: delete the 'fixed' clause: the buffer argument supplies the pointer and its length

// #3129 (§16.2b.8, §16.2b.11): a parameter is fixed or part of a buffer.
use c_import("static inline int put(const char *src, unsigned long n) { return 0; }\n")

c contract puts:
    fn put
        param src fixed null
        buffer param src len param n

fn main:
    print("unreachable")
