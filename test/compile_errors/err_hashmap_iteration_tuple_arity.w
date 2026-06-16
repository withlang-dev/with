//! expect-error: tuple pattern arity mismatch

fn main:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alpha", 1)
    for (_key, _value, _extra) in map:
        print("unreachable")
