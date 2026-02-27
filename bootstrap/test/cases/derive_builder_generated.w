@[derive(Builder)]
type Config = {
    host: str,
    port: i32 = 8080,
}

fn main -> i32:
    let a = Config.builder().host("localhost").build().unwrap()
    assert(a.host == "localhost")
    assert(a.port == 8080)

    let b = Config.builder().host("prod.example.com").port(443).build().unwrap()
    assert(b.port == 443)
