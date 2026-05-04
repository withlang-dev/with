//! skip
// Spec test: Section 9.5 — By-Value Self Method Chaining (formerly 25.54)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: consuming self with dot-notation
type Builder { host: str, port: u16 }
extend Builder:
    fn new -> Builder: Builder { host: "", port: 0 }
    fn host(self: Builder, h: str) -> Builder: { self with host: h }
    fn port(self: Builder, p: u16) -> Builder: { self with port: p }

fn test:
    let b = Builder.new()
        .host("localhost")
        .port(8080)
    assert(b.host == "localhost")
    assert(b.port == 8080)

// PASS: consuming self in final method
extend Builder:
    fn build(self: Builder) -> Result[Server, str]:
        if self.host.is_empty(): Err("missing host")
        else Ok(Server { host: self.host, port: self.port })

fn test:
    let server = Builder.new()
        .host("localhost")
        .port(8080)
        .build().unwrap()

// FAIL: use after consuming move
fn test_fail:
    let b = Builder.new()
    let b2 = b.host("x")     // b is moved
    b.port(80)                // ERROR: use of moved value `b`
