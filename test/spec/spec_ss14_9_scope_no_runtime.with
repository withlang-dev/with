//! args: --no-runtime
//! expect-stdout: ok
// §14.9: an ordinary (non-async) scope runs under --no-runtime.
fn main:
    let a = scope s =>:
        let h = s.spawn(() => 8)
        h.join()
    assert(a == 8)
    print("ok")
