// Test: HashMap convenience methods (increment/decrement/update/append)

fn plus_ten(x: i32) -> i32 =
    x + 10

fn main() -> i32 =
    var counts: HashMap[str, i32] = HashMap.new()

    counts.increment("apple")
    counts.increment("apple")
    counts.decrement("apple")
    assert(counts.get("apple").unwrap() == 1)

    counts.update("banana", 5, plus_ten)
    assert(counts.get("banana").unwrap() == 5)
    counts.update("banana", 5, plus_ten)
    assert(counts.get("banana").unwrap() == 15)

    var grouped: HashMap[str, Vec[i32]] = HashMap.new()
    grouped.append("nums", 10)
    grouped.append("nums", 20)
    let nums = grouped.get("nums").unwrap()
    assert(nums.len() == 2)
    assert(nums.get(0) == 10)
    assert(nums.get(1) == 20)

    0
