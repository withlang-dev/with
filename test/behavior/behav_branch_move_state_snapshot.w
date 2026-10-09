type Pair {
    a: List[i32],
    b: List[i32],
}

fn singleton(value: i32):
    let out: List[i32] = List.new()
    out.push(value)
    out

fn consume(values: List[i32]) -> i32:
    values[0]

fn main:
    var pair = Pair { a: singleton(1), b: singleton(2) }
    var first = move pair.a
    let one = consume(move first)
    var take_branch = true
    if take_branch:
        pair.a = singleton(3)
        var second = move pair.b
        let two = consume(move second)
        assert(one + two == 3)
        return
    var fallback = move pair.b
    let two = consume(move fallback)
    assert(one + two == 3)
