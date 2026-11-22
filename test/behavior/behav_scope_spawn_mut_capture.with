//! expect-stdout: ok

fn main:
    var value = 40
    scope s =>:
        let handle = s.spawn(() => { value = value + 2; 0 })
        let _ = handle.join()
    assert(value == 42)
    print("ok")
