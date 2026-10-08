//! expect-stdout: Ada! 3

// #1862 follow-up: `Person.name` has no return annotation and returns what
// `Named.name` declares (`str`, published from the trait contract, #1945).
// Default bodies for an impl were checked while collecting declarations,
// before that contract was published, so `self.name()` in `label` read the
// unannotated signature's Unit and the #1862 check reported "operand of
// `++` is Unit" on a call that returns `str`.

trait Named:
    fn name(self: &Self) -> str
    fn size(self: &Self) -> i32
    fn label(self: &Self) -> str: self.name() ++ "!"
    fn total(self: &Self) -> i32: self.size() + 1

type Person { text: str }

impl Named for Person:
    fn name: self.text
    fn size: 2

fn main:
    let person = Person { text: "Ada" }
    print(f"{person.label()} {person.total()}")
