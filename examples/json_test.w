// std.json — the safe document surface: JsonDocument.parse, field views,
// Deserialize for primitives and derived types, and JsonWriter round trips.
use std.json

fn expect(label: str, ok: bool): print(if ok: f"PASS: {label}" else: f"FAIL: {label}")

@[derive(Serialize, Deserialize)]
type InitParams { rootUri: str }

@[derive(Serialize, Deserialize)]
type InitRequest { method: str, id: i32, params: InitParams }

// An object with nested structure
let js = "{\"method\":\"initialize\",\"id\":1,\"params\":{\"rootUri\":\"/tmp\"}}"
let doc = JsonDocument.parse(js)
let root = doc.root()
expect("method val", root.field("method").raw() == "initialize")
expect("id val", i32.deserialize(root.field("id")) == 1)
expect("rootUri val", root.field("params").field("rootUri").raw() == "/tmp")

// Deserialize into a derived type
let req = InitRequest.deserialize(root)
expect("derived method", req.method == "initialize")
expect("derived id", req.id == 1)
expect("derived nested", req.params.rootUri == "/tmp")

// Arrays and primitives
let arr = JsonDocument.parse("{\"items\":[1, 2, 3, \"hello\", true, null],\"n\":3}")
let arr_root = arr.root()
expect("array raw", arr_root.field("items").raw() == "[1, 2, 3, \"hello\", true, null]")
expect("array sibling", i32.deserialize(arr_root.field("n")) == 3)

// Nested objects, empty containers, escapes, negatives, booleans and null
expect("nested field chain", JsonDocument.parse("{\"a\":{\"b\":{\"c\":\"deep\"}}}").root().field("a").field("b").field("c").raw() == "deep")
let empty_doc = JsonDocument.parse("{\"o\":{},\"a\":[]}")
let empty = empty_doc.root()
expect("empty obj", empty.field("o").raw() == "{}")
expect("empty arr", empty.field("a").raw() == "[]")
let esc_doc = JsonDocument.parse("{\"s\":\"hello\\nworld\",\"t\":\"tab\\there\"}")
let esc = esc_doc.root()
expect("escape n", str.deserialize(esc.field("s")) == "hello\nworld")
expect("escape t", str.deserialize(esc.field("t")) == "tab\there")
expect("neg int val", i32.deserialize(JsonDocument.parse("{\"x\":-42}").root().field("x")) == -42)
let bools_doc = JsonDocument.parse("{\"a\":true,\"b\":false,\"c\":null}")
let bools = bools_doc.root()
expect("true", bool.deserialize(bools.field("a")))
expect("false", not bool.deserialize(bools.field("b")))
expect("null raw", bools.field("c").raw() == "null")

// Serialize round trip
expect("serialize round trip", req.serialize(JsonWriter.new()).finish() == js)

// Curly braces in ordinary strings (once a lexer bug)
expect("curly in str len", "{abc}".len() == 5)
expect("unmatched curly len", "{unmatched".len() == 10)
expect("no braces len", "no braces".len() == 9)

print("all tests done")
