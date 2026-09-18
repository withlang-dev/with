use std.json.JsonWriter
fn main:
    var w = JsonWriter.new()
    w = w.begin_object()
    w = w.key("s")
    w = w.value_str("ab")
    w = w.end_object()
    print(w.finish())
