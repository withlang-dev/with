//! expect-stdout: a 5 6
//! expect-stdout: a 6 5
//! expect-stdout: b bee 7
//! expect-stdout: b bee! 8
//! expect-stdout: total a 11
//! expect-stdout: total b 10
//! expect-stdout: tag a
//! expect-stdout: tag b

// #1457: `Self { .. }` inside a module's impl or dotted method is that
// module's declaration, even when another module declares a type of the
// same name (§18.1). Sema left the literal untyped and MirLower resolved it
// by name to the newest `Item`, so module a's literal was built as module
// b's type (`a 5 0` / `a 0 0`).
//
// The method half: both `Item`s declare `total` (impl) and `tag` (dotted),
// and each module calls its own. A method symbol carries its owning
// declaration (`Item$m$<path>.total`), so the two never share one symbol;
// this was "method 'total' is declared for two different types named
// 'Item' ... not supported yet".
use issue1457.ca
use issue1457.cb

fn main:
    let a = new_a()
    print(show_a(&a))
    print(show_a(&a.twin_a()))
    let b = new_b()
    print(show_b(&b))
    print(show_b(&b.twin_b()))
    print(f"total a {total_a()}")
    print(f"total b {total_b()}")
    print(f"tag {tag_a()}")
    print(f"tag {tag_b()}")
