//! expect-exit: 0

// D27: a returned ephemeral aggregate originates only from its view-bearing
// fields. Its ordinary Copy fields do not pin their scalar arguments.

type TaggedView ephemeral { value: &i32, tag: i32 }

fn tagged(value: &i32, tag: i32) -> TaggedView: TaggedView { value, tag }

fn forward(value: &i32) -> TaggedView:
    let local_tag: i32 = 7
    tagged(value, local_tag)

fn main:
    let value: i32 = 41
    let view = forward(&value)
    assert(*view.value == 41)
    assert(view.tag == 7)
