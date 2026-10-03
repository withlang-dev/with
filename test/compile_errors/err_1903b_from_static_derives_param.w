//! expect-error: `first` declares `from static`, but its returned view derives from `p`: `from static` states a view of static data, with no parameter or global origin (§21.1 rule 6)

// #1903 (§21.1 rule 6, spec v7.18): `from static` is accepted only when the
// returned view has no parameter or global origin.

fn first(p: &Vec[i32]) -> &i32 from static: &p[0]

fn main:
    var x: Vec[i32] = Vec.new()
    x.push(1)
    print(*first(&x))
