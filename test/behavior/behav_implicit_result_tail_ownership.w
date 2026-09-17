//! expect-stdout: ok

type Payload { text: str, numbers: Vec[i32] }

fn direct(text: &str) -> Result[str, str]: text.clone()

fn branch(text: &str, left: bool) -> Result[str, str]:
    if left: text.clone()
    else: text.slice(0, text.len())

fn selected(text: &str, tag: i32) -> Result[str, str]:
    match tag:
        0 => text.clone()
        _ => text.slice(0, text.len())

fn vector(left: bool) -> Result[Vec[i32], str]:
    if left:
        let values: Vec[i32] = [11, 22, 33]
        values
    else:
        let values: Vec[i32] = [44, 55, 66]
        values

fn aggregate(text: &str, left: bool) -> Result[Payload, str]:
    if left: Payload { text: text.clone(), numbers: [11, 22] }
    else: Payload { text: text.clone(), numbers: [33, 44] }

fn main:
    for left in [true, false]:
        let original = branch("original value", left).unwrap()
        let replacement = branch("reused storage", left).unwrap()
        assert(original == "original value")
        assert(replacement == "reused storage")
        assert(direct("direct value").unwrap() == "direct value")
        for tag in [0, 1]:
            let first = selected("original value", tag).unwrap()
            let second = selected("reused storage", tag).unwrap()
            assert(first == "original value")
            assert(second == "reused storage")
        let first = vector(left).unwrap()
        let second = vector(not left).unwrap()
        assert(first[0] == (if left: 11 else: 44))
        assert(second[0] == (if left: 44 else: 11))
        let first_payload = aggregate("original value", left).unwrap()
        let second_payload = aggregate("reused storage", not left).unwrap()
        assert(first_payload.text == "original value")
        assert(second_payload.text == "reused storage")
        assert(first_payload.numbers[0] == (if left: 11 else: 33))
        assert(second_payload.numbers[0] == (if left: 33 else: 11))
    print("ok")
