type Resource = { name: str, count: i32 }

impl Resource =
    fn new(n: str) -> Resource = Resource { name: n, count: 0 }

fn main() -> i32 =
    let r = Resource.new("test")
    println(r.name)
    println(r.count)
    0
