// Test record update with multiple field overrides
type Config = {
    host: str,
    port: i32,
    debug: bool,
    workers: i32,
}

fn main() -> i32 =
    let base = Config {
        host: "localhost",
        port: 8080,
        debug: false,
        workers: 4,
    }
    let prod = { base with port: 443, debug: false, workers: 16 }
    println(prod.port)
    println(prod.workers)
    println(prod.debug)
    0
