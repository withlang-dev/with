//! expect-stdout: ok

fn main:
    let one = 1
    let same = 1
    let values = [1, 2, 3]
    let text = "abc"

    assert((one in values) == true)
    assert((one == same) == true)
    assert((text =~ /a/) == true)
    assert(0 < one < 2)
    print("ok")
