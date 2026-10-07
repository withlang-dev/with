//! expect-error: symbol 'HiddenT' is not visible from this module
// #2248 (§18.2): a type name in a comptime condition resolves as an annotation
// does: through the module's own imports. The evaluator read the flat type
// table, so this folded to 2 while `let t: HiddenT` was refused.
use issue2248.a

fn main:
    let n = comptime if HiddenT.is_copy(): 1 else: 2
    print(n)
