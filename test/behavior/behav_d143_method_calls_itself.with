//! expect-stdout: 3 9
//! expect-stdout: 24

// D143 (§9.1) holds for a method as for a free function: a package-local
// method with no return type that calls itself (`self.depth(…)`,
// `Tree.fact(…)`) takes the type its other paths give it. The self-call
// went unrecognized, the method kept the placeholder Unit, and a caller
// read "has type Unit".
type Tree { left: i32, right: i32, weight: i32 }

impl Tree:
    fn depth(n: i32):
        if n <= 0: return 0
        1 + self.depth(n - 1)

    fn total(n: i32, acc: i32):
        if n <= 0: acc else: self.total(n - 1, acc + self.weight)

fn Tree.fact(n: i32):
    if n <= 1: 1 else: n * Tree.fact(n - 1)

fn twice(v: i32): v * 2

fn main:
    let t = Tree { left: 1, right: 2, weight: 3 }
    print(f"{t.depth(3)} {t.total(3, 0)}")
    print(f"{twice(Tree.fact(4)) / 2}")
