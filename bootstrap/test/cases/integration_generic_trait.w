// Integration test: generic functions with trait-bounded types
trait Describable =
    fn desc(self: Self) -> str

type Named = { name: str }
type Numbered = { id: i32 }

impl Describable for Named =
    fn desc(self: Named) -> str: self.name

impl Describable for Numbered =
    fn desc(self: Numbered) -> str: "item"

fn print_desc[T: Describable](item: T) -> void:
    println(item.desc())

fn main -> i32:
    let n = Named { name: "hello" }
    let m = Numbered { id: 42 }
    print_desc(n)
    print_desc(m)
    0
