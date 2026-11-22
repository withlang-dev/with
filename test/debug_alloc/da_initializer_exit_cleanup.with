//! expect-debug-alloc: leak count=0

var drops = 0

type Resource { text: str }

impl Drop for Resource:
    move fn drop(): drops = drops + 1

fn resource(): Resource { text: f"owned {drops}" }

fn early_return(stop: bool):
    let value = if stop:
        return
    else:
        resource()
    assert(value.text.starts_with("owned"))

fn loop_exits():
    for i in 0..4:
        let value = if i == 0:
            continue
        else if i == 2:
            break
        else:
            resource()
        assert(value.text.starts_with("owned"))

fn goto_exit(stop: bool):
    'body:
        let value = if stop:
            goto 'exit
        else:
            resource()
        assert(value.text.starts_with("owned"))
    'exit:
        assert(true)

fn outcome(fail: bool) -> Result[i32, str]:
    if fail: return .Err("failure")
    .Ok(7)

fn error_return(fail: bool) -> Result[i32, str]:
    let value = if outcome(fail)? == 7:
        resource()
    else:
        resource()
    assert(value.text.starts_with("owned"))
    .Ok(7)

fn main:
    early_return(false)
    early_return(true)
    loop_exits()
    goto_exit(false)
    goto_exit(true)
    error_return(false)
    error_return(true)
    assert(drops == 4)
