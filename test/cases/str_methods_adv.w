// Test: advanced string method chains (trim, find, replace, slice, etc.)
fn main() -> i32 =
    // trim
    let padded = "  hello  "
    let trimmed = padded.trim()
    assert(trimmed == "hello")
    assert(trimmed.len() == 5)

    // find with valid and invalid targets
    let sentence = "the quick brown fox"
    assert(sentence.find("quick") == 4)
    assert(sentence.find("lazy") == 0 - 1)

    // replace chaining
    let original = "aaa bbb ccc"
    let step1 = original.replace("aaa", "xxx")
    assert(step1 == "xxx bbb ccc")
    let step2 = step1.replace("bbb", "yyy")
    assert(step2 == "xxx yyy ccc")

    // slice
    let text = "hello world"
    let first_word = text.slice(0, 5)
    assert(first_word == "hello")
    let second_word = text.slice(6, 11)
    assert(second_word == "world")

    // to_upper and to_lower
    let mixed = "Hello"
    let up = mixed.to_upper()
    assert(up == "HELLO")
    let lo = mixed.to_lower()
    assert(lo == "hello")

    // repeat
    let dash = "-"
    let line = dash.repeat(5)
    assert(line == "-----")
    assert(line.len() == 5)

    // starts_with and ends_with
    let path = "/usr/local/bin"
    assert(path.starts_with("/usr"))
    assert(path.ends_with("bin"))
    assert(not path.starts_with("bin"))
    assert(not path.ends_with("/usr"))

    // contains
    assert(path.contains("local"))
    assert(not path.contains("etc"))

    println("all advanced string method tests passed")
    0
