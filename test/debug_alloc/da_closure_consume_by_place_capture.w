//! expect-debug-alloc: leak count=0
//! expect-stdout: a
//! expect-stdout: b
//! expect-stdout: 7

// #1481 / §12.4: a closure whose body returns its by-place capture consumes
// the originating place when called: the value moves out once, the place is
// blanked (reset-on-move) and the frame's scope-exit drop frees nothing —
// exactly once, no double free (the old move-at-creation copied the bytes
// into the environment and `main` dropped the original too). A Drop struct
// consumed the same way runs its destructor exactly once (the guarded
// scope-exit drop must not run on the blanked place).
type R { id: i32 }
impl Drop for R:
    move fn drop(): print(self.id)

fn run_str(f: fn() -> str) -> str: f()

fn main:
    var c = "a".clone()
    let f: fn() -> str = () => c
    print(f())
    var d = "b".clone()
    print(run_str(() => d))
    let r = R { id: 7 }
    let take = () => r
    let got = take()
    let _keep = 0
