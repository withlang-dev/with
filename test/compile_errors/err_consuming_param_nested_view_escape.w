//! expect-error: returned view may outlive its origin 'b'

// #718 / D5 supersession (§3.8): the nested-field variant — a view into
// a nested field of a consuming `T` parameter dangles the same way the
// direct-field one does. Replaces behav_byvalue_view_escape_nested.w
// (retired share-place pin).

type Inner { data: i32 }
type Buf { inner: Inner }

fn nested_view(b: Buf) -> &i32: &b.inner.data

fn main:
    let b = Buf { inner: Inner { data: 7 } }
    let v = nested_view(b)
    print_i32(*v)
