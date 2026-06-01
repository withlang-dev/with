// Spec test: Section 4.3 — Default Field Values (formerly 25.42)

type Config {
    host: str = "localhost",
    port: u16 = 8080,
    debug: bool = false,
}

fn test_partial_defaults:
    let c = Config { port: 9090 }
    assert(c.host == "localhost")
    assert(c.port == 9090)
    assert(c.debug == false)

// PASS: override all fields
fn test_all_explicit:
    let c = Config { host: "0.0.0.0", port: 443, debug: true }
    assert(c.debug == true)

fn test_all_defaults:
    let c = Config {}
    assert(c.host == "localhost")
    assert(c.port == 8080)
    assert(c.debug == false)

fn test_shorthand:
    let host = "example.com"
    let c = Config { host, debug: true }
    assert(c.host == "example.com")
    assert(c.port == 8080)
    assert(c.debug == true)

// blocked: next_id() not defined
// type Counter { id: usize = next_id() }
// fn test_fresh:
//     let a = Counter {}
//     let b = Counter {}
//     assert(a.id != b.id)

// FAIL: omit field without default — covered by
// test/compile_errors/err_struct_missing_required_field.w.
// type Required {
//     name: str,
//     age: i32 = 0,
// }
// fn test_fail:
//     let r = Required { age: 25 }   // ERROR: missing field `name`
