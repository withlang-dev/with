//! expect-stdout: 15
//! expect-stdout: hello world
fn main:
    let nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)
    nums.push(4)
    nums.push(5)
    let iter = nums.iter()
    var total = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            total = total + item.unwrap()
        else:
            done = true
    print(int_to_string(total as i64))

    // VecIter[str]
    let words: Vec[str] = Vec.new()
    words.push("hello")
    words.push(" ")
    words.push("world")
    let witer = words.iter()
    var result = ""
    var wdone = false
    while not wdone:
        let w = witer.next()
        if w.is_some():
            result = result ++ w.unwrap()
        else:
            wdone = true
    print(result)
