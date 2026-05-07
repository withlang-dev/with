//! skip: non-executable spec sketch for Section 4.10 — Implicit Default Return (formerly 25.27c); contains pseudo-code for unimplemented feature work
// Spec test: Section 4.10 — Implicit Default Return (formerly 25.27c)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: i32 function ending with print — returns 0
fn demo -> i32:
    print("hello")
    // implicit 0

// PASS: bool function ending with statement — returns false
fn setup -> bool:
    print("initializing...")
    // implicit false

// PASS: f64 function ending with statement — returns 0.0
fn measure -> f64:
    print("measuring...")
    // implicit 0.0

// PASS: Option[T] function ending with statement — returns None
fn maybe_find -> Option[i32]:
    print("searching...")
    // implicit None

// PASS: explicit return still works
fn explicit_return -> i32:
    print("hello")
    42                       // not Unit — returned as-is

// FAIL: return type without Default — type mismatch
fn bad -> SomeTypeWithoutDefault:
    print("oops")
    // error: last expression is Unit but return type
    // SomeTypeWithoutDefault does not implement Default

// PASS: derive Default on user type
@[derive(Default)]
type Config { port: i32, debug: bool }

fn make_config -> Config:
    print("creating config...")
    // implicit Config { port: 0, debug: false }

// PASS: composes with implicit Ok wrapping
fn init -> Result[i32, IoError]:
    fs.create_dir("data")?
    // implicit Ok(0) — Ok wrapping + default return
