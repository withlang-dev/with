fn main:
    let x = 40 + 2
    no_suspend:
        let y = x + 1
        assert(y == 43)
    assert(x == 42)
