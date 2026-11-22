//! expect-error: unknown method 'serialize' for type 'NotSerializable'

use std.json

type NotSerializable {
    value: i32,
}

@[derive(Serialize)]
type Wrapper {
    field: NotSerializable,
}

fn main:
    let wrapper = Wrapper { field: NotSerializable { value: 1 } }
    let _ = wrapper.serialize(JsonWriter.new())
