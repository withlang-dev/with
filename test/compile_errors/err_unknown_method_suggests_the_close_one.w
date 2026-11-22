//! expect-check-fail: unknown method 'totl' for type 'Tally'
//! expect-check-fail: = help: did you mean `total`?
// An unknown method names the one the programmer most likely meant, as an
// unknown variable does (#3521).
type Tally { n: i32 }

impl Tally:
    fn total() -> i32: self.n

fn main:
    let t = Tally { n: 3 }
    print(f"{t.totl()}")
