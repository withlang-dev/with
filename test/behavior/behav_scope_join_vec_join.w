//! expect-stdout: left:right
//! expect-stdout: ok

fn main:
    let parts: Vec[str] = Vec.new()
    parts.push("left")
    parts.push("right")
    let joined = parts.join(":")
    print(joined)

    scope s =>:
        let handle = s.spawn(() => 7)
        assert(handle.join() == 7)

    print("ok")
