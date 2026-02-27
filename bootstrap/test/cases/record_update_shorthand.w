// Phase 2 gap: record update field shorthand not implemented
type Config = {
    port: i32,
    debug: bool,
}

fn main -> i32:
    let base = Config { port: 8080, debug: false }
    let port = 9090
    let updated = { base with port }
    if updated.port == 9090 and not updated.debug then 0 else 1
