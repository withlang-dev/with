//! expect-stdout: ok

// An early return transfers the local on its arm only. The continuing
// arm retains its cleanup, including cleanup of a nested owning payload.
var DROPS: i32 = 0

type Payload { bytes: str }
impl Drop for Payload:
    move fn drop():
        DROPS = DROPS + 1

type Signal { kind: i32, value: Payload }

fn choose(early: bool) -> Signal:
    var signal = Signal { kind: 0, value: Payload { bytes: "retained".to_owned() } }
    if early:
        return signal
    Signal { kind: 1, value: Payload { bytes: "result".to_owned() } }

fn choose_nested(early: bool) -> Signal:
    var signal = Signal { kind: 0, value: Payload { bytes: "retained".to_owned() } }
    if early:
        if signal.kind == 0:
            return signal
    Signal { kind: 1, value: Payload { bytes: "result".to_owned() } }

fn choose_match(early: bool) -> Signal:
    var signal = Signal { kind: 0, value: Payload { bytes: "retained".to_owned() } }
    match early:
        true => return signal
        false => ()
    Signal { kind: 1, value: Payload { bytes: "result".to_owned() } }

fn exercise(mode: i32, early: bool):
    let result = match mode:
        0 => choose(early)
        1 => choose_nested(early)
        _ => choose_match(early)
    assert(result.kind == if early: 0 else: 1)

fn main:
    for mode in 0i32..3:
        exercise(mode, false)
        assert(DROPS == mode * 3 + 2)
        exercise(mode, true)
        assert(DROPS == mode * 3 + 3)
    print("ok")
