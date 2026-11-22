//! expect-error: expected identifier

// A `{` after `match e:` opens a struct pattern, and `Some(x)` is not a
// field name. The parser once re-read the same token forever here (the
// field loop never advanced past a failed name); it must stop with the
// diagnostic. The inline form is `match o { Some(x) => x, None => 0 }`.
fn main:
    let o: Option[i32] = Some(1)
    let v: i32 = match o: { Some(x) => x, None => 0 }
    print_i32(v)
