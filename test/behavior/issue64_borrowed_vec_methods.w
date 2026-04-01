fn main:
    let nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)

    let shared = &nums
    assert(shared.len() == 3)
    assert(shared.contains(2))
    assert(shared.get(1) == 2)
    let iter = shared.iter()
    assert(iter.next().unwrap() == 1)
    let doubled = shared.map(x => x * 2)
    assert(doubled.get(0) == 2)
    let evens = shared.filter(x => x % 2 == 0)
    assert(evens.len() == 1)
    assert(evens.get(0) == 2)

    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("b")
    let words_ref = &words
    assert(words_ref.join(",") == "a,b")

    var nums_mut: Vec[i32] = Vec.new()
    nums_mut.push(7)
    nums_mut.push(8)
    nums_mut.push(9)
    let shared_mut = &mut nums_mut
    assert(shared_mut.pop() == 9)
    assert(shared_mut.remove(0) == 7)
    assert(shared_mut.len() == 1)
    assert(shared_mut.get(0) == 8)
