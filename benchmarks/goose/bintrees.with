const MAXDEPTH: i64 = 15 // BENCH_N
type Node { left: i32, right: i32 }
type Tree { nodes: Vec[Node] }

impl Tree:
    mut fn build(depth: i64) -> i32:
        var left: i32 = -1
        var right: i32 = -1
        if depth > 0:
            left = self.build(depth - 1)
            right = self.build(depth - 1)
        let index = self.nodes.len() as i32
        self.nodes.push(Node { left: left, right: right })
        index

    fn check(index: i32) -> i64:
        let node = self.nodes[index]
        if node.left < 0: 1
        else: 1 + self.check(node.left) + self.check(node.right)

fn tree_check(depth: i64) -> i64:
    var tree = Tree { nodes: Vec.new() }
    let root = tree.build(depth)
    tree.check(root)

fn main:
    print(tree_check(MAXDEPTH + 1))
    var long = Tree { nodes: Vec.new() }
    let root = long.build(MAXDEPTH)
    var depth: i64 = 4
    while depth <= MAXDEPTH:
        let iterations: i64 = 1 << ((MAXDEPTH - depth + 4) as u32)
        var sum: i64 = 0
        for _ in 0..iterations: sum += tree_check(depth)
        print(iterations)
        print(depth)
        print(sum)
        depth += 2
    print(long.check(root))
