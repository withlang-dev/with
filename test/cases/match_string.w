// Test match on string values
fn greet(name: str) -> str =
    match name
        "Alice" -> "Hello, Alice!"
        "Bob" -> "Hi, Bob!"
        _ -> "Hey there!"

fn main() -> i32 =
    println(greet("Alice"))
    println(greet("Bob"))
    println(greet("Charlie"))
    0
