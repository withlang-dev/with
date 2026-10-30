//! expect-debug-alloc: leak count=0
//! expect-stdout: 42
//! expect-stdout: 100001
// D172 (1): a method that grows its receiver's list is `mut fn`, so a view
// into that list cannot be held across the call (err_d172_fn_receiver_
// writes). Read before the growth, the view is the element; the list then
// reallocates many times and nothing reads the freed buffer.
type T:
    xs: List[i64]

impl T:
    mut fn grow():
        for i in 0..100000:
            self.xs.push(i)

fn main:
    var t = T { xs: [42] }
    let first = t.xs[0]
    print(first)
    t.grow()
    print(t.xs.len())
