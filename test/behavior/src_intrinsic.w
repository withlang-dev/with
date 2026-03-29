//! expect-stdout: ok
extern fn print(s: str) -> void

const BUILD_LOC: str = comptime src()

fn get_location() -> str:
    src()

fn main:
    assert(BUILD_LOC.len() > 0)
    let loc = src()
    // Just verify src() returns a non-empty string and doesn't crash
    assert(loc.len() > 0)
    let other = get_location()
    assert(other.len() > 0)
    print("ok")
