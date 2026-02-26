// Closures mutating captured variables
fn main -> i32:
    var count = 0
    let inc = || count = count + 1
    inc()
    inc()
    inc()

    var result = 0
    if count != 3: result = result + 1

    // Test: mutable capture with reading
    var total = 0
    let add = |x: i32| total = total + x
    add(10)
    add(20)
    add(30)
    if total != 60: result = result + 1

    println(result)
    result
