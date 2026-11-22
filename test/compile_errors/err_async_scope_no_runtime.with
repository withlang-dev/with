//! args: --no-runtime
//! expect-check-fail: async scope requires the fiber runtime
// §14.9: `async scope` needs the fiber runtime; --no-runtime rejects it.
fn go:
    async scope s =>:
        0
fn main:
    print("no")
