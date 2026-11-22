//! expect-stdout: ok
// #1043: binding a materialized string must not reset its borrowed source.
type Holder { text: str }

fn inspect(h: &Holder):
    let view = h.text
    assert(view == "abc")
    let typed: str = h.text
    assert(typed == "abc" and h.text == "abc")
    var typed_mut: str = h.text
    assert(typed_mut == "abc" and h.text == "abc")
    typed_mut = "changed again"
    assert(h.text == "abc")
    var explicit_clone = h.text
    assert(explicit_clone == "abc" and h.text == "abc")
    explicit_clone = "independent"
    assert(h.text == "abc")

fn main:
    let h = Holder { text: "a" ++ "bc" }
    inspect(h)
    assert(h.text == "abc")
    print("ok")
