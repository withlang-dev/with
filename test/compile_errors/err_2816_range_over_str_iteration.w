//! expect-check-fail: cannot iterate over `Range[str]`: `str` has no successor (§4.7: a range iterates `T: One + Ord`)
// #2816: a range over str reached codegen, where the integer range iterator
// asked LLVM for `@llvm.sadd.with.overflow` on a str ("LLVM function
// verification failed"). The for loop is refused in Sema; `'a'..='z'`, a
// range of code points, is the spelling that steps.
fn main:
    for c in "a".."z": print(c)
