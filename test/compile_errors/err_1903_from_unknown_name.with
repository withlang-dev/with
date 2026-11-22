//! expect-error: `from nope`: `nope` is neither a parameter of `first` nor a global (§21.1 rule 6)

// #1903 (§21.1 rule 6): a `from` entry names a parameter or a global.

fn first(p: &List[i32]) -> &i32 from nope: &p[0]

fn main:
    var x: List[i32] = List.new()
    x.push(1)
    print(*first(&x))
