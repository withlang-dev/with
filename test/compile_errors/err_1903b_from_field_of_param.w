//! expect-error: `from h.v` names a part of parameter `h`: each origin in a `from` clause names a parameter, `self`, or a global, whole, and `a.b` is a module-qualified global (§21.1 rule 6)

// #1903 (§21.1 rule 6, spec v7.18): `a.b` in a `from` clause is a
// module-qualified global, never a field of parameter `a`.

type H { v: Vec[i32] }

fn field(h: &H) -> &Vec[i32] from h.v: &h.v

fn main:
    let h = H { v: Vec.new() }
    print(field(&h).len())
