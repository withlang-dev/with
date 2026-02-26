// Test with block as scoped binding (form 3)
type Resource = { name: str, active: bool }

impl Resource =
    fn new(n: str) -> Resource = Resource { name: n, active: true }

fn main() -> i32 =
    with Resource.new("test") as r:
        println(r.name)
        println(r.active)
    0
