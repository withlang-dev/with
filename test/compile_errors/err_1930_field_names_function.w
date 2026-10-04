//! expect-error: bare 'limit' names both a field of the receiver `Gauge` and the function `limit` (§9.5)

// §9.5 (#1930): a bare name that names both a receiver field and a
// module-level function is a shadowing error; `self.limit` and the
// function's qualified name remain valid.

fn limit -> i32: 10

type Gauge {
    limit: i32,
}

impl Gauge:
    fn headroom -> i32: limit - 1

fn main:
    let g = Gauge { limit: 4 }
    print(f"{g.headroom()}")
