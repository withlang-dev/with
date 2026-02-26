// Test nested struct field access
type Address = { city: str, zip: i32 }
type Person = { name: str, addr: Address }

fn main() -> i32 =
    let addr = Address { city: "NYC", zip: 10001 }
    let p = Person { name: "Alice", addr: addr }
    println(p.name)
    println(p.addr.city)
    println(p.addr.zip)
    0
