//! expect-stdout: 15
//! expect-stdout: 3

fn main:
    // VecIter[T] implements Iter[T] — test via for-loop over .iter()
    let nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)
    nums.push(4)
    nums.push(5)
    var sum = 0
    for x in nums.iter():
        sum = sum + x
    print(int_to_string(sum as i64))

    // Manual .next() on VecIter
    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("b")
    words.push("c")
    let iter = words.iter()
    var count = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            count = count + 1
        else:
            done = true
    print(int_to_string(count as i64))
