//! expect-stdout: 1 2 3
// #2723 (D65): a call lowers against the signature Sema resolved for it in
// the calling module. MIR resolved the name again outside that context, and
// on Windows a program's own `fn accept(value: G)` met the runtime's Winsock
// `extern fn accept(s: i64, ...)`: the argument was lowered as a copy, and
// the caller dropped `G` again after `accept` had dropped it (2 for 1).
global var drops = 0
type G { text: str }
impl Drop for G:
    move fn drop(): drops += 1
fn identity[T](value: T): value
fn accept(value: G): assert(value.text == "owned")
fn listen(value: G): assert(value.text == "owned")
fn main:
    accept(identity(G { text: "owned" }))
    let a = drops
    accept(G { text: "owned" })
    let b = drops
    listen(identity(G { text: "owned" }))
    print(f"{a} {b} {drops}")
