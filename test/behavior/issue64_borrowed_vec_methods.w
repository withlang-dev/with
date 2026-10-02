fn main:
    var nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)

    // iter() is declared `mut fn` today, so it runs on the owned mutable
    // place before any shared view exists; iter()-through-&Vec is a filed
    // conformance gap (spec §13).
    var nums_iter = nums.iter()
    assert(nums_iter.next().unwrap() == 1)

    let shared = &nums
    assert(shared.len() == 3)
    assert(shared.contains(2))
    assert(shared[1] == 2)
    let doubled = shared.map(x => x * 2)
    assert(doubled[0] == 2)
    let evens = shared.filter(x => x % 2 == 0)
    assert(evens.len() == 1)
    assert(evens[0] == 2)

    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("b")
    let words_ref = &words
    assert(words_ref.join(",") == "a,b")

    var nums_mut: Vec[i32] = Vec.new()
    nums_mut.push(7)
    nums_mut.push(8)
    nums_mut.push(9)
    assert(nums_mut.pop().unwrap() == 9)
    assert(nums_mut.remove(0) == 7)
    assert(nums_mut.len() == 1)
    assert(nums_mut[0] == 8)
