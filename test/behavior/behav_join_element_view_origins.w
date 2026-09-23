//! expect-stdout: a
//! expect-stdout: 3
//! expect-stdout: b
//! expect-stdout: 3
//! expect-stdout: b
//! expect-stdout: a
//! expect-stdout: b
//! expect-stdout: b
//! expect-stdout: a
//! expect-stdout: a q
//! expect-stdout: 2

// #1406: a joined element view carries its origin, and the origin is free
// again after the view's last use (§3.5). An inner block's tail may view a
// binding declared outside the block; only the function body's tail is a
// return (the block-tail check used to treat every block as one).

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn joined_then_mutated(c: bool):
    var v = mkv()
    let x = if c: v[0] else: v[1]
    print(x)
    v.push("q".clone())
    print(v.len())

fn matched_then_mutated(k: i32):
    var v = mkv()
    let x = match k:
        0 => v[0]
        _ => v[1]
    print(x)
    v.push("q".clone())
    print(v.len())

fn arm_block_tail(c: bool):
    let v = mkv()
    let x = if c:
        let i = 1
        v[i]
    else:
        v[0]
    print(x)

fn arm_block_tail_ref(c: bool):
    let v = mkv()
    let x = if c:
        let i = 0
        &v[i]
    else:
        &v[1]
    print(x)

fn plain_block_tail():
    let v = mkv()
    let x = {
        let i = 1
        v[i]
    }
    print(x)

fn pick(v: &Vec[str], c: bool) -> &str: if c: v[0] else: v[1]

fn pick_arm_block(v: &Vec[str], c: bool) -> &str:
    if c:
        let i = 0
        v[i]
    else:
        v[1]

fn cloned_across_mutation(c: bool):
    var v = mkv()
    let x = if c: v[0].clone() else: v[1].clone()
    v[0] = "q".clone()
    print(f"{x} {v[0]}")

fn copy_join(c: bool):
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    let x: i32 = if c: v[0] else: v[1]
    v.push(3)
    print(x)

fn main:
    joined_then_mutated(true)
    matched_then_mutated(1)
    arm_block_tail(true)
    arm_block_tail_ref(true)
    plain_block_tail()
    let v = mkv()
    print(pick(&v, false))
    print(pick_arm_block(&v, true))
    cloned_across_mutation(true)
    copy_join(false)
