//! expect-debug-alloc: leak count=0
//! expect-stdout: 2 2 5 ab2 5 ab2
// A global's initializer drops its statement temporaries after the store,
// as a `let` statement does: `seed_list().len()` kept its List (64 bytes
// leaked per such global), since no statement frame was open to register
// it. A temporary that becomes the global's value is moved into it, never
// dropped as well. A global binding is a binding (D174): a view into a
// temporary is copied out independently (`last`, `text`; they read freed
// memory once the temporaries were dropped), and an annotation is an owned
// demand (`annotated` was a type mismatch).
fn seed_list() -> List[i64]:
    var xs: List[i64] = List.new()
    xs.push(4)
    xs.push(5)
    xs

fn word() -> str: f" ab{1 + 1} "

let count: i64 = seed_list().len()
let whole = seed_list()
let last = seed_list()[1]
let text = word().trim()
let text_len = word().len()
let annotated: str = word().trim()

fn main:
    print(f"{count} {whole.len()} {last} {text} {text_len} {annotated}")
