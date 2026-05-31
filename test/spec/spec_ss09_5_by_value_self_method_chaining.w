// Spec test: Section 9.5 — By-Value Self Method Chaining
//
// A method taking `self: Self` by value consumes the receiver and returns a
// new value, so calls chain. The body uses the `{ self with field: value }`
// functional-update syntax (spec lines 3088–3089) to produce the updated copy.

type Builder:
    host: str
    port: i32
    retries: i32

extend Builder:
    fn with_host(self: Builder, h: str) -> Builder: { self with host: h }
    fn with_port(self: Builder, p: i32) -> Builder: { self with port: p }
    // A single update can replace several fields at once.
    fn tune(self: Builder, p: i32, r: i32) -> Builder: { self with port: p, retries: r }

fn test_consuming_self_chaining:
    let b = Builder { host: "", port: 0, retries: 0 }.with_host("localhost").with_port(8080)
    assert(b.host == "localhost")
    assert(b.port == 8080)

fn test_update_preserves_other_fields:
    let b = Builder { host: "h", port: 1, retries: 9 }.with_port(2)
    assert(b.host == "h")     // untouched fields are carried over
    assert(b.retries == 9)
    assert(b.port == 2)

fn test_multi_field_update:
    let b = Builder { host: "h", port: 1, retries: 0 }.tune(8080, 3)
    assert(b.host == "h")
    assert(b.port == 8080)
    assert(b.retries == 3)
