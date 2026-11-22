//! expect-stdout: ok
// §15: f-string alignment, fill, and string precision.
fn main:
    assert(f"{42:<8}" == "42      ")
    assert(f"{42:>8}" == "      42")
    assert(f"{42:^8}" == "   42   ")
    assert(f"{42:_>8}" == "______42")
    assert(f"{\"hello world\":.5}" == "hello")
    print("ok")
