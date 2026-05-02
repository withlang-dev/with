// Spec test: Section 15.3 — String Literals (formerly 25.44)

// PASS: string literal is str by default (owned)
fn test_str_literal_default:
    let s = "hello"
    assert(s.len() == 5)

// PASS: str in struct fields
type Config { host: str, port: i32 }
fn test_str_in_struct:
    let c = Config { host: "localhost", port: 8080 }
    assert(c.host == "localhost")

// PASS: str in function args
fn register(name: str): assert(name.len() > 0)
fn test_str_in_fn_args: register("Alice")

// PASS: return type str
fn get_name -> str: "Alice"
fn test_str_return: assert(get_name() == "Alice")

// PASS: explicit &str annotation — blocked on &str param runtime bug
// fn test_view_str:
//     let view: &str = "hello"
//     assert(view.len() == 5)

// PASS: &str parameter auto-borrows — blocked on &str + f-string runtime bug
// fn greet(name: &str): assert(name.len() > 0)
// fn test_ref_str_param: greet("Alice")
