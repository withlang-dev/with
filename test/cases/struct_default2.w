// Test struct defaults with partial initialization
type Config = {
    host: str,
    port: i32 = 8080,
    debug: bool = false,
}

fn main -> i32:
    // Only specify required fields, rest use defaults
    let c = Config { host: "localhost" }
    println(c.host)
    println(c.port)
    println(c.debug)

    // Override one default
    let c2 = Config { host: "prod", port: 443 }
    println(c2.host)
    println(c2.port)
    println(c2.debug)
