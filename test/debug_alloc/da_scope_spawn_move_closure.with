//! expect-debug-alloc: leak count=0
//! expect-stdout: 9
//! expect-stdout: 10
//! expect-stdout: by place 11
//! expect-stdout: ok

// §12.4 (D63), §14, #1539 finding: a closure handed to a scope's `spawn`
// is moved into the task, and the worker thread runs that closure. MIR
// built the closure and passed it by move, but nothing registered the move,
// so the statement temp that held it was dropped right after the spawn
// (validate-ownership: a drop of a Moved place); codegen meanwhile built the
// worker a second time from the AST, and a `move ()` closure's second build
// captured `v` after the first had moved it out: the thread read it empty
// and printed 7 and 7.

fn joined(k: i32) -> i32:
    let v = f"x{k}"
    let a = scope s =>:
        let h = s.spawn(move () => v.len() as i32 + 7)
        h.join()
    a

fn by_place(k: i32) -> i32:
    let v = f"xy{k}"
    let a = scope s =>:
        let h = s.spawn(() => v.len() as i32 + 8)
        h.join()
    a

fn main:
    print(joined(1))
    print(joined(22))
    print(f"by place {by_place(1)}")
    print("ok")
