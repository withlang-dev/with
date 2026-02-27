fn main:
    let s = "struct " ++ "Foo" ++ " {\n"
    println(i32_to_str(s.len() as i32))
    println(s)

extern fn i32_to_str(n: i32) -> str
