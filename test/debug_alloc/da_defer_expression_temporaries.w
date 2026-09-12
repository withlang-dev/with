//! expect-debug-alloc: leak count=0

// Every cleanup expression borrows a newly allocated temporary. Exercise
// both sides of each exit so neither a leak nor an off-path drop is hidden.
var visits = 0

fn observe(text: &str):
    assert(text.starts_with("cleanup"))
    visits = visits + 1

fn early_return(early: bool):
    defer: observe(f"cleanup{visits}")
    if early: return
    assert(true)

fn loop_exits():
    for i in 0..3:
        defer: observe(f"cleanup{visits}")
        if i == 0: continue
        if i == 1: break
        assert(false)

fn goto_exit(early: bool):
    'body:
        defer: observe(f"cleanup{visits}")
        if early: goto 'exit
        assert(true)
    'exit:
        assert(true)

fn outcome(fail: bool) -> Result[i32, str]:
    if fail: return .Err("failure")
    .Ok(7)

fn error_return(fail: bool) -> Result[i32, str]:
    defer: observe(f"cleanup{visits}")
    errdefer: observe(f"cleanup{visits}")
    let value = outcome(fail)?
    .Ok(value)

fn nested(early: bool):
    defer:
        observe(f"cleanup{visits}")
        defer: observe(f"cleanup{visits}")
    if early: return
    assert(true)

fn main:
    early_return(false)
    early_return(true)
    loop_exits()
    goto_exit(false)
    goto_exit(true)
    error_return(false)
    error_return(true)
    nested(false)
    nested(true)
    assert(visits == 13)
