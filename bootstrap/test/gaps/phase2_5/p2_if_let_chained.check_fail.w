// Phase 2: chained if-let is implemented (parser + sema + lowering)
type A = AVal(i32) | ANone
type B = BVal(i32) | BNone

fn main -> i32:
    if let AVal(x) = AVal(1), let BVal(y) = BVal(2):
        if x + y == 3 then 0 else 1
    else
        1
