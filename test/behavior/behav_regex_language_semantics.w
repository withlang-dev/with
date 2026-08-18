//! expect-stdout: ok

fn test_global_match_operator_progresses:
    let text = "a1 b2"
    var count = 0

    while text =~ /([a-z])(\d)/g:
        if count == 0:
            assert($0 == "a1")
            assert($1 == "a")
            assert($2 == "1")
        else if count == 1:
            assert($0 == "b2")
            assert($1 == "b")
            assert($2 == "2")
        else:
            assert(false)
        count += 1

    assert(count == 2)

    if text =~ /([a-z])(\d)/g:
        assert($0 == "a1")
    else:
        assert(false)

fn test_regex_match_arm_captures:
    let line = "key=value"
    let out = match line:
        /^(\w+)=(\w+)$/ => $1 ++ ":" ++ $2
        _ => "missing"
    assert(out == "key:value")

fn main:
    test_global_match_operator_progresses()
    test_regex_match_arm_captures()
    with_write("ok\n")
