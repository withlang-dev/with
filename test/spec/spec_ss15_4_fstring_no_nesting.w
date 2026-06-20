//! expect-stdout: ok

fn test_bind_inner_first:
    let x = 7
    let inner = f"inner {x}"
    let outer = f"outer {inner} end"
    assert(outer == "outer inner 7 end")

fn test_escaped_braces_still_work:
    let x = 7
    assert(f"{{" == "{")
    assert(f"}}" == "}")
    assert(f"{{{x}}}" == "{7}")

fn test_plain_string_braces_still_work:
    let x = 7
    let plain = "{x}"
    assert(plain == "{x}")
    assert(f"value {x}" == "value 7")

fn main:
    test_bind_inner_first()
    test_escaped_braces_still_work()
    test_plain_string_braces_still_work()
    print("ok")
