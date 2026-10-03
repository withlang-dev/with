//! expect-stdout: true false true
//! expect-stdout: true false

// #2009: `x in c` over a generic owner's `contains` is checked through
// Sema.check_generic_method_call, whose ephemeral-argument gate read the
// argument as `get_extra(get_data1(node) + i)`. For an `in` node, d1 is
// the lhs node's id, not an argument list, so a view operand (`k: &i32`,
// ephemeral) sent an unrelated node to the escape check. On the stage2
// compiler the `k in b` below read node 9815 for lhs node 9698 (lldb at
// SemaCheck.w:25437). The argument now comes from the caller's
// `extra_start`, the slot the `in` node records for its operand. A view on
// either side of `in`, and the same method called directly.

type Bag[T] { items: Vec[T] }

impl[T] Bag[T]:
    fn contains(value: &T) -> bool:
        for x in self.items:
            if x == *value: return true
        false

fn main:
    var v: Vec[i32] = Vec.new()
    v.push(3)
    let b: Bag[i32] = Bag { items: v }
    let k: &i32 = &b.items[0]
    print(f"{k in b} {7 in b} {b.contains(k)}")
    let rb: &Bag[i32] = &b
    print(f"{k in rb} {8 in rb}")
