//! expect-error: invalid format spec `>8q`: `q` is not part of

// #1823 (§15.4.1, §15.4.8): text a format spec's grammar does not accept is
// refused. An unknown mode letter was silently dropped and the value
// printed as if the spec had ended before it.
fn main:
    let h = "hello"
    print(f"[{h:>8q}]")
