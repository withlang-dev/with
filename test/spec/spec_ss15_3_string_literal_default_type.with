// Spec test: Section 15.3 — String Literal Default Type (formerly 25.87)

// PASS: literal is str by default — no annotation
fn test_string_literal_default_str:
    let s = "hello"
    assert(s.len() == 5)

// PASS: str in struct field — no annotation on literal
type LiteralDefaultConfig { host: str, port: i32 }
fn test_string_literal_struct_field:
    let c = LiteralDefaultConfig { host: "localhost", port: 8080 }
    assert(c.host == "localhost")

// PASS: str in function parameter
fn literal_default_greet(name: str): assert(name.len() > 0)
fn test_string_literal_function_parameter: literal_default_greet("Alice")

// PASS: literal can coerce to &str in parameter position
fn literal_default_greet_view(name: &str): assert(name.len() > 0)
fn test_string_literal_ref_parameter: literal_default_greet_view("Bob")

// PASS: str in return type
fn literal_default_name -> str: "Alice"
fn test_string_literal_return_type: assert(literal_default_name() == "Alice")

// PASS: explicit &str annotation gives static reference
fn test_string_literal_explicit_view:
    let view: &str = "hello"  // &str — zero-cost, no allocation
    assert(view.len() == 5)
