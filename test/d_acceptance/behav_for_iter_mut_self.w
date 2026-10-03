//! expect-stdout: 15
//! expect-stdout: done

fn main:
    // For-loop over vec.iter() — desugared through hardcoded MIR path
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

    // For-loop directly over Vec
    let words: Vec[str] = Vec.new()
    words.push("done")
    for w in words:
        print(w)
