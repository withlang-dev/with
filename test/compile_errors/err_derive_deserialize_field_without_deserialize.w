//! expect-error: unknown method 'deserialize' for type 'NotDeserializable'

use std.json

type NotDeserializable {
    value: i32,
}

@[derive(Deserialize)]
type Wrapper {
    value: NotDeserializable,
}

fn main:
    let doc = JsonDocument.parse("{\"value\":{\"value\":1}}")
    let _wrapper = Wrapper.deserialize(doc.root())
