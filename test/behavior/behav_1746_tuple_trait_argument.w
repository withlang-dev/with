//! expect-stdout: 1 10
//! expect-stdout: 2 20
//! expect-stdout: 7 1
//! expect-stdout: 7 2

// §11 / §13.2 (#1746): a tuple is a trait type argument like any other —
// `impl Iter[(A, B)]` is how `zip` and `enumerate` yield pairs. The impl
// header's parser once pushed a tuple argument's elements into the
// argument run itself, so the trait saw the wrong `T` and refused `next`.
type Pairs { n: i32 }

impl Iter[(i32, i32)] for Pairs:
    mut fn next() -> Option[(i32, i32)]:
        if self.n >= 2:
            return None
        self.n += 1
        Some((self.n, self.n * 10))

type GPairs[A] { a: A, n: i32 }

impl[A: Copy] Iter[(A, i32)] for GPairs[A]:
    mut fn next() -> Option[(A, i32)]:
        if self.n >= 2:
            return None
        self.n += 1
        Some((self.a, self.n))

fn main:
    var p = Pairs { n: 0 }
    for (x, y) in p:
        print(f"{x} {y}")
    var g = GPairs { a: 7, n: 0 }
    for (x, y) in g:
        print(f"{x} {y}")
