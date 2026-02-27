// Test string indexing

fn main -> i32:
    let s = "hello"
    let first = s[0]
    let last = s[4]
    // 'h' = 104, 'o' = 111
    assert(first == 104)
    assert(last == 111)
    // 'e' = 101, 'l' = 108
    assert(s[1] == 101)
    assert(s[2] == 108)
