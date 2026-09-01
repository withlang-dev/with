//! expect-error: returned view may outlive its origin 'b'

// #718 / D5 supersession (§3.8): a plain consuming `T` parameter is OWNED
// by the callee — even when its physical ABI is indirect — and dies when
// the callee returns, so a view derived from it dangles. This replaces
// behav_byvalue_view_escape_tail.w, which pinned the retired share-place
// reading ("by-value param is the caller's place; escaping views valid").
// The borrow spelling (`b: &Buf`) remains the legal way to return a view.

type Buf { data: i32 }

fn first_view(b: Buf) -> &i32: &b.data

fn main:
    let b = Buf { data: 1 }
    let v = first_view(b)
    print_i32(*v)
