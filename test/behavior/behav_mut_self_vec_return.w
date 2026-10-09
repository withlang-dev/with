//! expect-stdout: ok
// D7: a builder method that returns self CONSUMES it — `move fn` with the
// `var out = self` rebind idiom (the pre-D7 `mut self: Thing` transition
// form is receiver-mode-enforced away; see std.build's migration).

type Thing {
    name: str,
    items: List[str],
}

impl Thing:
    move fn add(item: str) -> Thing:
        var out = self
        out.items.push(item)
        out

type Wrapper {
    label: str,
    value: i32,
}

impl Wrapper:
    move fn set_value(v: i32) -> Wrapper:
        var out = self
        out.value = v
        out

fn main:
    var t = Thing { name: "test", items: List.new() }
    t = t.add("hello")
    t = t.add("world")
    assert(t.items.len() == 2)
    assert(t.items[0] == "hello")
    assert(t.items[1] == "world")

    var w = Wrapper { label: "scalar", value: 0 }
    w = w.set_value(42)
    assert(w.value == 42)

    print("ok")
