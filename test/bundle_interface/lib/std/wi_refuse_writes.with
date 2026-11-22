// D39 emitter refusal fixture (§21.1 rule 1): an exported function's writes
// of exported globals are a declared, checked contract, and no declaration
// means it writes none. `bump` writes the exported `COUNT` through the
// private `step` and declares nothing, so --emit-bundle-interface must fail
// naming `bump`, `COUNT` and the call path. `SCRATCH` is private: writing it
// is not part of the interface, so `reset` is accepted.
pub var COUNT: i32 = 0
var SCRATCH: i32 = 0
fn step(): COUNT = COUNT + 1
pub fn bump(): step()
pub fn reset(): SCRATCH = 0
