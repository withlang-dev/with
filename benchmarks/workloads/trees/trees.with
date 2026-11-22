// Binary trees: allocation-heavy recursive tree build and check, depth 18.
// Timed region: everything. Checksum: sum of all node counts.
use std.time
use std.box.Box

const MIN_DEPTH: i32 = 4
const MAX_DEPTH: i32 = 18

type Node { left: Option[Box[Node]], right: Option[Box[Node]] }

fn bottom_up(depth: i32) -> Box[Node]:
    if depth == 0: Box.new(Node { left: None, right: None })
    else: Box.new(Node { left: Some(bottom_up(depth - 1)), right: Some(bottom_up(depth - 1)) })

fn check(node: &Node) -> i64:
    let left = match &node.left:
        Some(child) => check(child.as_ref())
        None => 0
    let right = match &node.right:
        Some(child) => check(child.as_ref())
        None => 0
    1 + left + right

fn main:
    let start = now_ns()
    var total: i64 = 0
    let stretch = bottom_up(MAX_DEPTH + 1)
    total = total + check(stretch.as_ref())
    let long_lived = bottom_up(MAX_DEPTH)
    var depth = MIN_DEPTH
    while depth <= MAX_DEPTH:
        let iterations = 1 << ((MAX_DEPTH - depth + MIN_DEPTH) as u32)
        for _ in 0..iterations:
            let tree = bottom_up(depth)
            total = total + check(tree.as_ref())
        depth += 2
    total = total + check(long_lived.as_ref())
    let elapsed_ms = (now_ns() - start) as f64 / 1000000.0
    print(f"max_depth {MAX_DEPTH}")
    print(f"elapsed_ms {elapsed_ms:.3}")
    print(f"checksum {total}")
