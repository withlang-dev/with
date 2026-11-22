//! expect-check-fail: shadowing is not allowed for 'LIMIT'

// #1221 (§18.2): the later import shadows the earlier, but a module's own
// declaration is not an import — declaring a name twice in one module is
// still an error.

let LIMIT = 1
let LIMIT = 2

fn main:
    print(LIMIT)
