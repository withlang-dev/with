//! expect-stdout: later
//! expect-stdout: 0 1 2 3
//! expect-stdout: 9
//! expect-stdout: 1 2 3 4 5 6 7
//! expect-stdout: 3

// D69 (§13.4): a generator value holds only its arguments, so it can be
// stored — here in a struct — and consumed later; a generator may consume
// another, itself included, and yield what it receives (a recursive tree
// walk). The tree is index-linked: a type recursive through Vec is #1557.
gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

type Job[G] {
    name: str,
    source: G,
}

type Node {
    value: i32,
    kids: Vec[i32],
}

gen fn walk(nodes: &Vec[Node], at: i32) -> i32:
    yield nodes[at].value
    for kid in nodes[at].kids:
        for v in walk(nodes, kid):
            yield v

fn node(value: i32, kids: Vec[i32]) -> Node: Node { value, kids }

fn main:
    let job = Job { name: "later".clone(), source: upto(4) }
    print(job.name)
    var out = ""
    for v in move job.source:
        out = out ++ (if out.len() > 0: " " else: "") ++ f"{v}"
    print(out)
    let first = upto(3)
    let second = upto(4)
    var sum = 0
    for v in first:
        sum += v
    for v in second:
        sum += v
    print(sum)
    var nodes: Vec[Node] = Vec.new()
    nodes.push(node(1, [1, 4]))
    nodes.push(node(2, [2, 3]))
    nodes.push(node(3, []))
    nodes.push(node(4, []))
    nodes.push(node(5, [5, 6]))
    nodes.push(node(6, []))
    nodes.push(node(7, []))
    var order = ""
    for v in walk(&nodes, 0):
        order = order ++ (if order.len() > 0: " " else: "") ++ f"{v}"
    print(order)
    var seen = 0
    for v in walk(&nodes, 0):
        seen += 1
        if v == 3: break
    print(seen)
