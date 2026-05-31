// Spec test: Section 9.5 — By-Value Self Method Chaining
// `{ self with f: v }` update syntax is not yet supported, so methods rebuild explicitly.

type Builder:
    host: str
    port: i32

extend Builder:
    fn with_host(self: Builder, h: str) -> Builder: Builder { host: h, port: self.port }
    fn with_port(self: Builder, p: i32) -> Builder: Builder { host: self.host, port: p }

fn test_consuming_self_chaining:
    let b = Builder { host: "", port: 0 }.with_host("localhost").with_port(8080)
    assert(b.host == "localhost")
    assert(b.port == 8080)
