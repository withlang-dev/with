// #1967: a module exporting a type named `T`. A generic function that
// imports this module and names its own type parameter `T` must see the
// parameter, not this struct.
pub type T { v: i32 }

pub fn make_t(v: i32) -> T: T { v }
