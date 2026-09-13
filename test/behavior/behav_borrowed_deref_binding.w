//! expect-stdout: ok

use std.collections.Vec

fn observe(source: &str):
    let value = *source
    assert(value == "alpha")

fn main:
    var values: Vec[str] = Vec.new()
    values.push("alpha".clone())
    values.push("gamma".clone())
    for i in 0..32:
        observe(values.get(0))
        assert(values.get(0).cmp(values.get(1)) < 0)
        assert(values.get(1).cmp(values.get(0)) > 0)
        let scratch = "other".clone()
        assert(scratch == "other")
        assert(values.get(0) == "alpha")
        assert(values.get(1) == "gamma")
    print("ok")
