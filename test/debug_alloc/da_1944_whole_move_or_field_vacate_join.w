//! expect-debug-alloc: leak count=0
//! expect-stdout: whole 1
//! expect-stdout: vacate 1
//! expect-stdout: member whole 1
//! expect-stdout: member vacate 1
//! expect-stdout: ok

// D82: one scope exit reached by a path that whole-moved the value and by a
// path that vacated one of its fields. The whole-moved path runs the
// destructor once (in the consumer) and the vacated path runs it once at
// the scope exit with the field empty; neither leaks nor frees twice. The
// same for a member of a plain struct: whole-moved out on one branch, its
// field vacated (twice) on the other.

var DROPS: i32 = 0

type Value { text: str }
impl Drop for Value:
    move fn drop():
        DROPS += 1

type Holder { kind: i32, value: Value }

fn eat(v: Value): assert(v.text == "a")

fn mixed(whole: bool):
    var v = Value { text: "a".to_owned() }
    if whole:
        eat(v)
    else:
        let t = move v.text
        assert(t == "a")

fn member_mixed(whole: bool):
    var h = Holder { kind: 3, value: Value { text: "a".to_owned() } }
    if whole:
        eat(move h.value)
    else:
        let t = move h.value.text
        assert(t == "a")
    assert(h.kind == 3)

fn main:
    mixed(true)
    print(f"whole {DROPS}")
    DROPS = 0
    mixed(false)
    print(f"vacate {DROPS}")
    DROPS = 0
    member_mixed(true)
    print(f"member whole {DROPS}")
    DROPS = 0
    member_mixed(false)
    print(f"member vacate {DROPS}")
    print("ok")
