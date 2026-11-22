//! expect-stdout: ok

use std.json

@[derive(Serialize)]
type User {
    name: str,
    age: i32,
    admin: bool,
}

@[derive(Serialize)]
type Boxed[T] {
    value: T,
    label: str,
}

// #770 pin: two type params + a non-Copy instantiation exercise the
// generated impl's multi-tp bound records (ct_copy_type_params_with_bound).
@[derive(Serialize)]
type Pair[K, V] {
    key: K,
    value: V,
}

fn main:
    let escaped = JsonWriter.new().value_str("a\"b\\c").finish()
    assert(escaped == "\"a\\\"b\\\\c\"")

    let user = User { name: "Ada", age: 37, admin: true }
    let user_json = user.serialize(JsonWriter.new()).finish()
    assert(user_json == "{\"name\":\"Ada\",\"age\":37,\"admin\":true}")

    let boxed: Boxed[i32] = Boxed { value: 42, label: "answer" }
    let boxed_json = boxed.serialize(JsonWriter.new()).finish()
    assert(boxed_json == "{\"value\":42,\"label\":\"answer\"}")

    let named: Boxed[str] = Boxed { value: "hi", label: "greeting" }
    let named_json = named.serialize(JsonWriter.new()).finish()
    assert(named_json == "{\"value\":\"hi\",\"label\":\"greeting\"}")

    let pair: Pair[str, i32] = Pair { key: "a", value: 1 }
    let pair_json = pair.serialize(JsonWriter.new()).finish()
    assert(pair_json == "{\"key\":\"a\",\"value\":1}")

    print("ok")
