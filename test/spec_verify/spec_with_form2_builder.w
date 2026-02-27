// POSITIVE: with Form 2 — mutable builder binding (§7.2)
type Config = { timeout: i32, retries: i32 }

fn main -> i32:
    let cfg = with Config { timeout: 10, retries: 1 } as mut c:
        c.timeout = 30
        c.retries = 3
    assert(cfg.timeout == 30)
    assert(cfg.retries == 3)
    println("with form2 builder ok")
