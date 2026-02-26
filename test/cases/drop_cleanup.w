// Test: Drop function called at scope exit
type Resource = { id: i32 }

fn Resource.drop(self: Resource) -> void:
    println("dropped")

fn main -> i32:
    let r = Resource { id: 1 }
    let _ = r
