// Test string concatenation and comparison

fn main -> i32:
    let a = "hello"
    let b = " world"
    let c = a + b
    println(c)
    assert(c.len == 11)

    // String comparison
    assert("hello" == "hello")
    assert("foo" != "bar")

    let x = "abc"
    let y = "abc"
    assert(x == y)

    let z = x + "d"
    assert(z == "abcd")
    assert(z != "abc")
    assert(z.len == 4)
