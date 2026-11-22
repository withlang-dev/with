use common

const DEPTH: i64 = 16 // BENCH_N
type Node { v: i32, left: i32, right: i32 }
type Tree { nodes: Vec[Node] }

impl Tree:
    mut fn build(depth: i64, seed: u64) -> i32:
        var left: i32 = -1
        var right: i32 = -1
        if depth > 0:
            left = self.build(depth - 1, xs_next(seed))
            right = self.build(depth - 1, xs_next(seed +% 1))
        let index = self.nodes.len() as i32
        self.nodes.push(Node { v: xs_mod(seed, 1000) as i32, left: left, right: right })
        index

    fn sum(index: i32, pass: i64) -> i64:
        let node = self.nodes[index]
        var total: i64 = node.v ^ pass
        if node.left >= 0: total += self.sum(node.left, pass)
        if node.right >= 0: total += self.sum(node.right, pass)
        total

fn main:
    var tree = Tree { nodes: Vec.new() }
    let root = tree.build(DEPTH, 12345)
    var total: i64 = 0
    for p in 0..8: total += tree.sum(root, p)
    print(tree.nodes.len())
    print(total)
