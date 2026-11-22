//! expect-error: `grow` mutates its receiver (`self.xs.push`, line 12); declare it `mut fn grow`
// D172 (1), §9: a `fn` receiver is read-only for every write through it,
// std container mutations included. `grow` pushed through its read
// receiver while a caller held a view into the list: reading `first`
// after the call read freed memory (printed 0 for 42).
type T:
    xs: List[i64]

impl T:
    fn grow():
        for i in 0..100000:
            self.xs.push(i)

fn main:
    var t = T { xs: [42] }
    let first = t.xs[0]
    t.grow()
    print(first)
