// std.json — the safe document surface: JsonDocument.parse, field views,
// Deserialize for primitives and derived types, and JsonWriter round trips.

use std.json

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}")
    else:
        print(f"FAIL: {label}")

@[derive(Serialize, Deserialize)]
type InitParams {
    rootUri: str,
}

@[derive(Serialize, Deserialize)]
type InitRequest {
    method: str,
    id: i32,
    params: InitParams,
}

fn main:
    // ── Test 1: Object with nested structure ──
    let js = "{\"method\":\"initialize\",\"id\":1,\"params\":{\"rootUri\":\"/tmp\"}}"
    // The document keeps its source (parse takes an owned str), so the
    // copy the round-trip test compares against is spelled.
    let doc = JsonDocument.parse(js.clone())
    let root = doc.root()
    expect("method val", root.field("method").raw() == "initialize")
    expect("id val", i32.deserialize(root.field("id")) == 1)
    expect("rootUri val", root.field("params").field("rootUri").raw() == "/tmp")

    // ── Test 2: Deserialize into a derived type ──
    let req = InitRequest.deserialize(root)
    expect("derived method", req.method == "initialize")
    expect("derived id", req.id == 1)
    expect("derived nested", req.params.rootUri == "/tmp")

    // ── Test 3: Array and primitives ──
    let arr_doc = JsonDocument.parse("{\"items\":[1, 2, 3, \"hello\", true, null],\"n\":3}")
    let arr_root = arr_doc.root()
    expect("array raw", arr_root.field("items").raw() == "[1, 2, 3, \"hello\", true, null]")
    expect("array sibling", i32.deserialize(arr_root.field("n")) == 3)

    // ── Test 4: Nested objects ──
    let nested = JsonDocument.parse("{\"a\":{\"b\":{\"c\":\"deep\"}}}")
    expect("nested field chain", nested.root().field("a").field("b").field("c").raw() == "deep")

    // ── Test 5: Empty object ──
    let empty = JsonDocument.parse("{\"o\":{},\"a\":[]}")
    expect("empty obj", empty.root().field("o").raw() == "{}")
    expect("empty arr", empty.root().field("a").raw() == "[]")

    // ── Test 6: Escape sequences ──
    let esc = JsonDocument.parse("{\"s\":\"hello\\nworld\",\"t\":\"tab\\there\"}")
    expect("escape n", str.deserialize(esc.root().field("s")) == "hello\nworld")
    expect("escape t", str.deserialize(esc.root().field("t")) == "tab\there")

    // ── Test 7: Negative integer ──
    let neg = JsonDocument.parse("{\"x\":-42}")
    expect("neg int val", i32.deserialize(neg.root().field("x")) == -42)

    // ── Test 8: Boolean and null ──
    let bools = JsonDocument.parse("{\"a\":true,\"b\":false,\"c\":null}")
    expect("true", bool.deserialize(bools.root().field("a")))
    expect("false", not bool.deserialize(bools.root().field("b")))
    expect("null raw", bools.root().field("c").raw() == "null")

    // ── Test 9: Serialize round trip ──
    let written = req.serialize(JsonWriter.new()).finish()
    expect("serialize round trip", written == js)

    // ── Test 10: Curly braces in regular strings (was lexer bug) ──
    let s1 = "{abc}"
    expect("curly in str len", s1.len() == 5)
    let s2 = "{unmatched"
    expect("unmatched curly len", s2.len() == 10)
    let s3 = "no braces"
    expect("no braces len", s3.len() == 9)

    print("all tests done")
