//! expect-stdout: ok

// D16 applies to an explicit reference parameter too: the moved value
// dies with the call statement, including grouped and projected spellings.
var DROPS: i32 = 0
type Payload { bytes: str }
type Holder { payload: Payload }
impl Drop for Payload:
    move fn drop(): DROPS = DROPS + 1

fn observe(value: &Payload) -> i32:
    assert(value.bytes == "retained")
    7

fn exercise:
    let value = Payload { bytes: "retained".to_owned() }
    observe(move value)
    assert(DROPS == 1)
    let grouped = Payload { bytes: "retained".to_owned() }
    observe((move grouped))
    assert(DROPS == 2)
    var holder = Holder { payload: Payload { bytes: "retained".to_owned() } }
    observe(move holder.payload)
    assert(DROPS == 3)
    let conditional = Payload { bytes: "retained".to_owned() }
    if observe(move conditional) == 7:
        assert(DROPS == 4)
    observe(Payload { bytes: "retained".to_owned() })
    assert(DROPS == 5)

fn main:
    exercise()
    assert(DROPS == 5)
    print("ok")
