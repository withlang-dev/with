use std.hash

type Inline { x: i32, y: i32 }
    with Copy

type Block {
    x: i32,
    y: i32,
}
    with Copy

type SameLine {
    x: i32,
    y: i32,
} with Copy, Eq

const INLINE_IS_COPY: bool = comptime Inline.is_copy()
const BLOCK_IS_COPY: bool = comptime Block.is_copy()
const SAME_LINE_IS_COPY: bool = comptime SameLine.is_copy()
const SAME_LINE_HAS_EQ: bool = comptime SameLine.implements(Eq)
const SAME_LINE_IS_KEY: bool = comptime SameLine.implements(Key)

fn take_inline(p: Inline) -> i32:
    p.x + p.y

fn take_same_line(p: SameLine) -> i32:
    p.x + p.y

fn main:
    assert(INLINE_IS_COPY)
    assert(BLOCK_IS_COPY)
    assert(SAME_LINE_IS_COPY)
    assert(SAME_LINE_HAS_EQ)
    assert(SAME_LINE_IS_KEY)

    let inline = Inline { x: 1, y: 2 }
    let inline_sum = take_inline(inline)
    assert(inline_sum == 3)
    assert(inline.x == 1)

    let a = SameLine { x: 4, y: 5 }
    let b = SameLine { x: 4, y: 5 }
    assert(a == b)
    let same_line_sum = take_same_line(a)
    assert(same_line_sum == 9)
    assert(a.x == 4)
    assert(hash_of(&SameLine { x: 4, y: 5 }) == hash_of(&SameLine { x: 4, y: 5 }))
    assert(hash_of(&SameLine { x: 4, y: 5 }) != hash_of(&SameLine { x: 5, y: 4 }))
