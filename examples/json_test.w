use std.json

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn main():
    var token_storage: [128]JsonToken
    let tokens = &token_storage[0] as *mut JsonToken

    // ── Test 1: Object with nested structure ──
    var p1 = JsonParser.new()
    let js = "{\"method\":\"initialize\",\"id\":1,\"params\":{\"rootUri\":\"/tmp\"}}"
    let count = json_parse(&mut p1 as *mut JsonParser, js, tokens, 128)
    expect("object: 9 tokens", count == 9)
    expect("method key", json_str(js, tokens, 1) == "method")
    expect("method val", json_str(js, tokens, 2) == "initialize")
    expect("id key", json_str(js, tokens, 3) == "id")
    expect("rootUri key", json_str(js, tokens, 7) == "rootUri")
    expect("rootUri val", json_str(js, tokens, 8) == "/tmp")

    // ── Test 2: json_find ──
    let mi = json_find(js, tokens, 0, "method")
    expect("find method idx", mi == 2)
    expect("find method val", json_str(js, tokens, mi) == "initialize")

    let ii = json_find(js, tokens, 0, "id")
    expect("find id idx", ii == 4)
    expect("find id val", json_int(js, tokens, ii) == 1)

    let pi = json_find(js, tokens, 0, "params")
    expect("find params idx", pi == 6)

    let ui = json_find(js, tokens, pi, "rootUri")
    expect("find rootUri idx", ui == 8)
    expect("find rootUri val", json_str(js, tokens, ui) == "/tmp")

    expect("find missing", json_find(js, tokens, 0, "nope") < 0)

    // ── Test 3: Array ──
    var p3 = JsonParser.new()
    let arr = "[1, 2, 3, \"hello\", true, null]"
    let r3 = json_parse(&mut p3 as *mut JsonParser, arr, tokens, 128)
    expect("array: 7 tokens", r3 == 7)
    expect("arr[0] = 1", json_int(arr, tokens, 1) == 1)
    expect("arr[1] = 2", json_int(arr, tokens, 2) == 2)
    expect("arr[2] = 3", json_int(arr, tokens, 3) == 3)
    expect("arr[3] = hello", json_str(arr, tokens, 4) == "hello")
    expect("arr[4] = true", json_str(arr, tokens, 5) == "true")
    expect("arr[5] = null", json_str(arr, tokens, 6) == "null")

    // ── Test 4: Incomplete JSON (previously broken — { in string literal) ──
    var p4 = JsonParser.new()
    let incomplete = "{\"key\":"
    let r4 = json_parse(&mut p4 as *mut JsonParser, incomplete, tokens, 128)
    expect("incomplete obj", r4 == JSON_ERROR_PART)

    // ── Test 5: Incomplete array ──
    var p5 = JsonParser.new()
    let r5 = json_parse(&mut p5 as *mut JsonParser, "[1, 2", tokens, 128)
    expect("incomplete arr", r5 == JSON_ERROR_PART)

    // ── Test 6: Nested arrays ──
    var p6 = JsonParser.new()
    let nested = "[[1,2],[3,4]]"
    let r6 = json_parse(&mut p6 as *mut JsonParser, nested, tokens, 128)
    expect("nested arrays: 7 tokens", r6 == 7)

    // ── Test 7: Empty object and array ──
    var p7a = JsonParser.new()
    let r7a = json_parse(&mut p7a as *mut JsonParser, "{}", tokens, 128)
    expect("empty obj: 1 token", r7a == 1)

    var p7b = JsonParser.new()
    let r7b = json_parse(&mut p7b as *mut JsonParser, "[]", tokens, 128)
    expect("empty arr: 1 token", r7b == 1)

    // ── Test 8: Escape sequences ──
    var p8 = JsonParser.new()
    let esc = "[\"hello\\nworld\", \"tab\\there\"]"
    let r8 = json_parse(&mut p8 as *mut JsonParser, esc, tokens, 128)
    expect("escapes: 3 tokens", r8 == 3)

    // ── Test 9: Negative integer ──
    var p9 = JsonParser.new()
    let neg = "{\"x\":-42}"
    let r9 = json_parse(&mut p9 as *mut JsonParser, neg, tokens, 128)
    expect("neg int parse: 3 tokens", r9 == 3)
    let xi = json_find(neg, tokens, 0, "x")
    expect("neg int val", json_int(neg, tokens, xi) == 0 - 42)

    // ── Test 10: Boolean and null ──
    var p10 = JsonParser.new()
    let bools = "{\"a\":true,\"b\":false,\"c\":null}"
    let r10 = json_parse(&mut p10 as *mut JsonParser, bools, tokens, 128)
    expect("bool/null: 7 tokens", r10 == 7)
    expect("true str", json_str(bools, tokens, json_find(bools, tokens, 0, "a")) == "true")
    expect("false str", json_str(bools, tokens, json_find(bools, tokens, 0, "b")) == "false")
    expect("null str", json_str(bools, tokens, json_find(bools, tokens, 0, "c")) == "null")

    // ── Test 11: Curly braces in regular strings (was lexer bug) ──
    let s1 = "{abc}"
    expect("curly in str len", s1.len() == 5)
    let s2 = "{unmatched"
    expect("unmatched curly len", s2.len() == 10)
    let s3 = "no braces"
    expect("no braces len", s3.len() == 9)

    print("all tests done\n")
