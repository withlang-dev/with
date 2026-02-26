// Test nested with expressions
type Config = {
    host: str,
    port: i32 = 8080,
}

fn main() -> i32 =
    let c = with Config { host: "localhost", port: 3000 } as config:
        println(config.host)
        println(config.port)
        config
    println(c.port)
    0
