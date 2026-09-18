//! thread probe 4: compiler-builtin scoped spawn (ScopedJoinHandle producer).
fn main:
    let base = 40
    scope s =>:
        let handle = s.spawn(() => base + 2)
        assert(handle.join() == 42)
    print("ok")
