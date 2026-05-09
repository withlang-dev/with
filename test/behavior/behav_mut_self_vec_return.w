//! expect-stdout: ok

type Thing {
    name: str,
    items: Vec[str],
}

fn Thing.add(mut self: Thing, item: str) -> Thing:
    self.items.push(item)
    self

type Wrapper {
    label: str,
    value: i32,
}

fn Wrapper.set_value(mut self: Wrapper, v: i32) -> Wrapper:
    self.value = v
    self

fn main:
    var t = Thing { name: "test", items: Vec.new() }
    t = t.add("hello")
    t = t.add("world")
    assert(t.items.len() == 2)
    assert(t.items.get(0) == "hello")
    assert(t.items.get(1) == "world")

    var w = Wrapper { label: "scalar", value: 0 }
    w = w.set_value(42)
    assert(w.value == 42)

    print("ok")
