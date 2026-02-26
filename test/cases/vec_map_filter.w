// Test Vec with manual map/filter pattern
fn main -> i32:
    var nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)
    nums.push(4)
    nums.push(5)

    // Manual filter: collect evens
    var evens: Vec[i32] = Vec.new()
    for x in nums
        if x % 2 == 0:
            evens.push(x)
    
    println(evens.len())
    
    // Sum
    var sum = 0
    for x in evens
        sum = sum + x
    println(sum)
