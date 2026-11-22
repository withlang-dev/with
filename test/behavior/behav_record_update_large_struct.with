//! expect-stdout: ok

type LoopVars {
    v0: i32,
    v1: i32,
    v2: i32,
    v3: i32,
    v4: i32,
    v5: i32,
    v6: i32,
    v7: i32,
}

fn set(vars: LoopVars, slot: i32, value: i32) -> LoopVars:
    if slot == 0: return { vars with v0: value }
    if slot == 1: return { vars with v1: value }
    if slot == 2: return { vars with v2: value }
    if slot == 3: return { vars with v3: value }
    if slot == 4: return { vars with v4: value }
    if slot == 5: return { vars with v5: value }
    if slot == 6: return { vars with v6: value }
    if slot == 7: return { vars with v7: value }
    vars

fn main:
    let vars = set(LoopVars {
        v0: 0,
        v1: 0,
        v2: 0,
        v3: 0,
        v4: 0,
        v5: 0,
        v6: 0,
        v7: 0,
    }, 7, 9)
    assert(vars.v7 == 9)
    assert(vars.v2 == 0)
    print("ok")
