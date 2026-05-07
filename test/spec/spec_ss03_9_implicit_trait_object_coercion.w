//! skip: non-executable spec sketch for Section 3.9 — Implicit Trait Object Coercion (formerly 25.92); contains pseudo-code for unimplemented feature work
// Spec test: Section 3.9 — Implicit Trait Object Coercion (formerly 25.92)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: &T → &dyn Trait
trait Greet:
    fn hello(self: &Self) -> str
type English {}
impl Greet for English:
    fn hello(self: &Self) -> str: "Hello"

fn say_hi(g: &dyn Greet) -> str: g.hello()
fn test:
    let eng = English {}
    assert(say_hi(&eng) == "Hello")       // auto-coerce &English → &dyn Greet

// PASS: Box[T] → Box[dyn Trait]
fn test:
    let g: Box[dyn Greet] = Box.new(English {})  // auto-coerced
    assert(g.hello() == "Hello")

// PASS: combined auto-ref + trait coercion
fn test:
    let eng = English {}
    assert(say_hi(eng) == "Hello")        // auto-ref + auto-coerce
