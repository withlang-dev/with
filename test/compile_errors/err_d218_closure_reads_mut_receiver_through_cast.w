//! expect-check-fail: `x` is held as a `mut` place for this call, and a closure passed in the same call captures it (§3.2)

// D218 (§3.2): the read is found under any expression form (a cast and a method call hid it from the per-kind capture walk).
type Inner { items: List[i32], m: i32 }
impl Inner:
    mut fn each(body: fn(i32) -> i32) -> i32:
        var t = 0
        for v in self.items: t += body(v)
        t

type Bag { n: i32, inner: Inner }

fn bump(mut b: Inner, body: fn(i32) -> i32) -> i32: b.each(body)

fn main:
    var x = Bag { n: 2, inner: Inner { items: [1, 2, 3], m: 4 } }
    print(x.inner.each((v) => v + x.inner.items.len() as i32))
