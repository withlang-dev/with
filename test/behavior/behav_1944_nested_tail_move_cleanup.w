//! expect-stdout: ok

// A nested tail moves a field out before its containing value's custom
// destructor runs. The destructor must receive the reset field.
var DROPS: i32 = 0
type Value { text: str }
impl Drop for Value:
    move fn drop():
        DROPS = DROPS + 1
type Signal { kind: i32, value: Value }

fn choose(early: bool, take: bool) -> Signal:
    let text = if take:
        var assembled = Signal { kind: 0, value: Value { text: "retained".to_owned() } }
        if early:
            return assembled
        move assembled.value.text
    else:
        "other".to_owned()
    Signal { kind: 1, value: Value { text: move text } }

fn exercise(early: bool, take: bool):
    let result = choose(early, take)
    assert(result.kind == if early and take: 0 else: 1)
    assert(result.value.text == if take: "retained" else: "other")

fn main:
    exercise(false, true)
    assert(DROPS == 2)
    exercise(true, true)
    assert(DROPS == 3)
    exercise(false, false)
    assert(DROPS == 4)
    print("ok")
