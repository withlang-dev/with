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

fn main:
    let escaped = JsonWriter.new().value_str("a\"b\\c").finish()
    assert(escaped == "\"a\\\"b\\\\c\"")

    let user = User { name: "Ada", age: 37, admin: true }
    let user_json = user.serialize(JsonWriter.new()).finish()
    assert(user_json == "{\"name\":\"Ada\",\"age\":37,\"admin\":true}")

    let boxed: Boxed[i32] = Boxed { value: 42, label: "answer" }
    let boxed_json = boxed.serialize(JsonWriter.new()).finish()
    assert(boxed_json == "{\"value\":42,\"label\":\"answer\"}")

    print("ok")
