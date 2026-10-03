//! expect-stdout: 3
// A view's later uses are found in its own file. The scan for a use after a
// mutation compared byte offsets across every module: `count` in
// lib/phantom_count_peer.w, padded to land inside this file's `for` below,
// read as a use of this `count` after `self.add(i)`, and the program was
// refused ("cannot mutate `self` while `count` is a live view into it").
// Found as MirLower.w's update_string_fields_after_aggregate refused by an
// edit to Sema.w.
use lib.phantom_count_peer

type B { xs: Vec[i32], ys: Vec[i32] }

impl B:
    mut fn add(v: i32): self.ys.push(v)

    mut fn fill():
        let count = self.xs[0]
        for i in 0..count:
            self.add(i)
            let doubled_value_kept_for_width = i * 2 + i * 2 - i * 2

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(3)
    var b = B { xs, ys: Vec.new() }
    b.fill()
    print(peer_len(&b.ys))
