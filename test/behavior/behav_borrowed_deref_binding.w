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
        observe(values[0])
        assert(values[0].cmp(values[1]) < 0)
        assert(values[1].cmp(values[0]) > 0)
        let scratch = "other".clone()
        assert(scratch == "other")
        assert(values[0] == "alpha")
        assert(values[1] == "gamma")
    print("ok")
