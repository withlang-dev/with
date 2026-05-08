//! expect-stdout: ok

fn test_compile_match_find:
    let re = Regex.compile("^(\\w+)\\s+(\\w+)$").unwrap()
    assert(re.is_match("hello world"))
    assert(not re.is_match("hello"))

    let digits = Regex.compile("\\d+").unwrap()
    let first = digits.find("abc123def").unwrap()
    assert(first.text == "123")
    assert(first.start == 3)
    assert(first.end == 6)

    let second = digits.find_at("abc123def45", 7).unwrap()
    assert(second.text == "45")
    assert(second.start == 9)
    assert(second.end == 11)

    let all = digits.find_all("a1b22c333")
    assert(all.len() == 3)
    assert(all.get(0).text == "1")
    assert(all.get(1).text == "22")
    assert(all.get(2).text == "333")

fn test_captures:
    let re = Regex.compile("^(?<key>\\w+)=(?<value>\\w+)$").unwrap()
    let caps = re.captures("name=with").unwrap()
    assert(caps.len() == 3)
    assert(caps.get(0).unwrap().text == "name=with")
    assert(caps.get(1).unwrap().text == "name")
    assert(caps.get(2).unwrap().text == "with")
    assert(caps.name("key").unwrap().text == "name")
    assert(caps.name("value").unwrap().text == "with")
    assert(re.num_captures() == 2)
    assert(re.capture_index("key").unwrap() == 1)
    assert(re.capture_index("value").unwrap() == 2)

fn test_replace_split:
    let digits = Regex.compile("\\d+").unwrap()
    assert(digits.replace("a1b22c", "#") == "a#b22c")
    assert(digits.replace_all("a1b22c", "#") == "a#b#c")

    let pair = Regex.compile("(?<key>\\w+)=(\\w+)").unwrap()
    assert(pair.replace("x=one y=two", "${key}:$2") == "x:one y=two")
    assert(pair.replace_all("x=one y=two", "$1:$$:$2") == "x:$:one y:$:two")

    let parts = digits.split("a1b22c")
    assert(parts.len() == 3)
    assert(parts.get(0) == "a")
    assert(parts.get(1) == "b")
    assert(parts.get(2) == "c")

    let limited = digits.splitn("a1b22c333d", 2)
    assert(limited.len() == 2)
    assert(limited.get(0) == "a")
    assert(limited.get(1) == "b22c333d")

fn test_literals_and_operators:
    let re = /\d+/
    assert(re.is_match("abc123"))
    assert("abc123" =~ /\d+/)
    assert("abc" !~ /\d+/)

    let kind = match "abc123":
        /\d+$/ => "number suffix"
        _ => "other"
    assert(kind == "number suffix")

fn main:
    test_compile_match_find()
    test_captures()
    test_replace_split()
    test_literals_and_operators()
    print("ok")
