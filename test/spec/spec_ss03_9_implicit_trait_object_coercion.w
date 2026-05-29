// Spec test: Section 3.9 — Implicit Trait Object Coercion.

trait Greet:
    fn hello(self: &Self) -> str

type English {}

impl Greet for English:
    fn hello(self: &Self) -> str: "Hello"

fn accept(g: &dyn Greet) -> str:
    g.hello()

fn test_explicit_ref_coerces_to_dyn_trait:
    let eng = English {}
    assert(accept(&eng) == "Hello")

fn test_value_auto_refs_and_coerces_to_dyn_trait:
    let eng = English {}
    assert(accept(eng) == "Hello")
