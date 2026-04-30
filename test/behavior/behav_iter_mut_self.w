//! expect-stdout: 15
//! expect-stdout: a b c

fn main:
    // Test 1: VecIter[i32].next() with mut self semantics
    let nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)
    nums.push(4)
    nums.push(5)
    var sum = 0
    let iter = nums.iter()
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            sum = sum + item.unwrap()
        else:
            done = true
    print(int_to_string(sum as i64))

    // Test 2: VecIter[str].next() with mut self semantics
    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("b")
    words.push("c")
    var result = ""
    let witer = words.iter()
    var wdone = false
    while not wdone:
        let w = witer.next()
        if w.is_some():
            if result != "":
                result = result ++ " "
            result = result ++ w.unwrap()
        else:
            wdone = true
    print(result)
