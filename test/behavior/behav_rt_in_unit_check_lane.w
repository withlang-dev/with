//! env: WITH_RT_IN_UNIT=1
//! check-only

// D30 R2b lane pin: with the runtime parsed into the unit (embedded rt
// sources joining the prelude prefix), a user program must still CHECK
// clean — every decl/def seam between the extern-decl world and the real
// runtime bodies (signature drift, prelude-name collisions, unsafe
// honesty, effect pins) surfaces here. `run` under the lane is R2c scope
// (rooting + link suppression); this pin holds the sema ground R2b won.
use std.builtins.print

fn main:
    var v: List[str] = List.new()
    v.push("a" ++ "")
    print(v.join("-"))
    print(f"{v.len()}")
