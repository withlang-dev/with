type Inner = { value: i32 }
type Outer = { name: str, data: Inner }

fn main() -> i32 =
    let inner = Inner { value: 42 }
    let outer = Outer { name: "test", data: inner }
    println(outer.name)
    println(outer.data.value)
    0
