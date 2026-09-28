//! expect-stdout: hello!
//! expect-stdout: ab!

// #1822 (§9.5, D12/D21): a `mut fn` receiver is the caller's place. A body
// that replaces it whole drops the old value and leaves the new one for the
// caller to drop. audit:all's ownership validator called that a leak; the
// deep-debug-tool-tests audit this file.

type Label:
    text: str

extend str:
    mut fn bang(): self = self ++ "!"

extend Label:
    mut fn bang(): self = Label { text: self.text ++ "!" }

fn main:
    var m = "hello"
    m.bang()
    print(m)
    var l = Label { text: "a" ++ "b" }
    l.bang()
    print(l.text)
