use std.json
use std.builtins.int_to_string

// Audit probe: reachable surface only (JsonWriter/Serialize,
// JsonDocument/JsonView/Deserialize). Raw JsonParser/json_parse are
// module-private (see report); oracle = python3 json.

fn pi(n: i32):
    print(int_to_string(n as i64) ++ "\n")

fn main():
    // ── Writer ──
    let o = JsonWriter.new().begin_object().key("name").value_str("Ada").key("age").value_i32(37).key("admin").value_bool(true).end_object().finish()
    print(o ++ "\n")
    let esc = JsonWriter.new().value_str("a\"b\\c").finish()
    print(esc ++ "\n")
    let ctl = JsonWriter.new().value_str("n\nt\tr").finish()
    print(ctl ++ "\n")
    let neg = JsonWriter.new().begin_object().key("x").value_i32(0 - 42).key("big").value_i64(5000000000i64).key("t").value_bool(false).end_object().finish()
    print(neg ++ "\n")
    let raw = JsonWriter.new().value_raw("null").finish()
    print(raw ++ "\n")
    let empty = JsonWriter.new().begin_object().end_object().finish()
    print(empty ++ "\n")

    // ── JsonDocument + Deserialize ──
    let doc = JsonDocument.parse("{\"name\":\"Ada\",\"age\":37,\"big\":5000000000,\"admin\":true,\"nested\":{\"x\":-42},\"s\":\"a\\\"b\\\\c\\nd\"}")
    let root = doc.root()
    print(str.deserialize(root.field("name")) ++ "\n")
    pi(i32.deserialize(root.field("age")))
    print(int_to_string(i64.deserialize(root.field("big"))) ++ "\n")
    print_bool(bool.deserialize(root.field("admin")))
    print("\n")
    print(root.field("admin").raw() ++ "\n")
    pi(i32.deserialize(root.field("nested").field("x")))
    let s = str.deserialize(root.field("s"))
    print(s ++ "\n")

    // ── Roundtrip of a \b escape through Deserialize -> Serialize ──
    let doc2 = JsonDocument.parse("{\"s\":\"a\\bb\"}")
    let s2 = str.deserialize(doc2.root().field("s"))
    let out2 = JsonWriter.new().begin_object().key("s").value_str(s2).end_object().finish()
    print(out2 ++ "\n")
