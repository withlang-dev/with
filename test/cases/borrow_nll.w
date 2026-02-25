fn use_ref(r: *const i32) -> i32 =
    42

fn main() -> i32 =
    var x: i32 = 10
    let result = use_ref(&x)
    x = 42
    x
