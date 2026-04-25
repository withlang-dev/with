//! skip
// Spec test: Section 11.8 — derive(Builder) (formerly 25.96)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: generated builder with required and optional fields
@[derive(Builder)]
type Config {
    host: str,
    port: i32 = 8080,
}

fn test:
    let c = Config.builder()
        .host("localhost")
        .build()
        .unwrap()
    assert(c.host == "localhost")
    assert(c.port == 8080)

// PASS: override defaults
fn test:
    let c = Config.builder()
        .host("prod.example.com")
        .port(443)
        .build()
        .unwrap()
    assert(c.port == 443)
