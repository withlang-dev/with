//! expect-stdout: ok

use std.json

@[derive(Serialize, Deserialize)]
type User {
    name: str,
    age: i32,
    admin: bool,
}

@[derive(Serialize, Deserialize)]
type Boxed[T] {
    value: T,
    label: str,
}

fn main:
    let user_doc = JsonDocument.parse("{\"name\":\"Ada\",\"age\":37,\"admin\":true}")
    let user = User.deserialize(user_doc.root())
    assert(user.name == "Ada")
    assert(user.age == 37)
    assert(user.admin)

    let escaped_doc = JsonDocument.parse("{\"name\":\"a\\\"b\\\\c\",\"age\":1,\"admin\":false}")
    let escaped = User.deserialize(escaped_doc.root())
    assert(escaped.name == "a\"b\\c")
    assert(escaped.age == 1)
    assert(not escaped.admin)

    let boxed_doc = JsonDocument.parse("{\"value\":42,\"label\":\"answer\"}")
    let boxed = Boxed[i32].deserialize(boxed_doc.root())
    assert(boxed.value == 42)
    assert(boxed.label == "answer")

    let roundtrip = boxed.serialize(JsonWriter.new()).finish()
    assert(roundtrip == "{\"value\":42,\"label\":\"answer\"}")

    print("ok")
