//! expect-stdout: issue334 final else expr passed

fn inline_colon(flag: bool) -> i32:
    if flag: 10 else: 20

fn indented_colon(flag: bool) -> i32:
    if flag:
        30
    else: 40

fn braced(flag: bool) -> i32:
    if flag { 50 } else: 60

fn mixed_chain(x: i32) -> str:
    if x < 0:
        "negative"
    else if x == 0 { "zero" }
    else: "positive"

fn main:
    assert(inline_colon(true) == 10)
    assert(inline_colon(false) == 20)

    assert(indented_colon(true) == 30)
    assert(indented_colon(false) == 40)

    assert(braced(true) == 50)
    assert(braced(false) == 60)

    assert(mixed_chain(-1) == "negative")
    assert(mixed_chain(0) == "zero")
    assert(mixed_chain(1) == "positive")

    let chain = if false: 1 else if true: 2 else: 3
    assert(chain == 2)

    print("issue334 final else expr passed")
