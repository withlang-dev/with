//! expect-stdout: 1:11 2:12 3:13
//! expect-stdout: 20 40
//! expect-stdout: 0:a 1:b
//! expect-stdout: 6 2 true 4

// §13.2 / §13.3 (#1746): the iterator adapters work on any Iter[T]
// implementor — a user type and std's Pulled[T] — not only the built-in
// iterator types: written once in std.iter over the trait.
type Counter { n: i32, limit: i32 }

impl Iter[i32] for Counter:
    mut fn next() -> Option[i32]:
        if self.n >= self.limit:
            return None
        self.n += 1
        Some(self.n)

gen fn letters() -> str:
    yield "a".clone()
    yield "b".clone()

fn main:
    let a = Counter { n: 0, limit: 3 }
    let b = Counter { n: 10, limit: 13 }
    var out = ""
    for (x, y) in a.zip(b):
        out = if out.len() == 0: f"{x}:{y}" else: out ++ f" {x}:{y}"
    print(out)
    let c = Counter { n: 0, limit: 5 }
    let evens = c |> filter(*it % 2 == 0) |> map(it * 10) |> collect[Vec]()
    print(f"{evens[0]} {evens[1]}")
    var tagged = ""
    for (i, s) in letters().pull().enumerate():
        tagged = if tagged.len() == 0: f"{i}:{s}" else: tagged ++ f" {i}:{s}"
    print(tagged)
    let d = Counter { n: 0, limit: 3 }
    let total = d.fold(0, (acc, x) => acc + x)
    let e = Counter { n: 0, limit: 6 }
    let dropped = e.drop(2).take(2).count()
    let f = Counter { n: 0, limit: 3 }
    let any3 = f.any(*it == 3)
    let g = Counter { n: 0, limit: 10 }
    let pos = g.chain(Counter { n: 0, limit: 2 }).take_while(*it < 5).position(*it == 4).unwrap() + 1
    print(f"{total} {dropped} {any3} {pos}")
