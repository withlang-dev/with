//! expect-debug-alloc: leak count=0

trait Named:
    fn name(self: &Self) -> str
    fn label(self: &Self) -> str: self.name() ++ "!"

type Person { text: str }

impl Named for Person:
    fn name: self.text.clone()

fn main:
    let person = Person { text: "Ada" }
    assert(person.label() == "Ada!")
