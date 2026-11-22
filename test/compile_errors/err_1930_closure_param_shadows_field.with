//! expect-error: shadowing is not allowed for 'n': it names a field of the receiver `Acc`, which this method reaches by its bare name (§9.5)

// §9.5 (#1930), §29.8: a closure parameter inside the method is a parameter
// in the method's body too.

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

type Acc {
    n: i32,
}

impl Acc:
    mut fn bumped(x: i32) -> i32: apply(n => n + 1, x)

fn main:
    var a = Acc { n: 1 }
    print(f"{a.bumped(2)}")
