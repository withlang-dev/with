//! expect-stdout: 0 1 3 4 5 6 100 201
// D172 (§3.8a, §3.2a): a `mut` parameter mutates the caller's place in place
// without taking it; any parameter may be `mut`, and passing one on is a
// `mut` use. Exclusive access begins when the call does: an argument may
// mutate the place a `mut` receiver names when its result retains nothing
// of it (`pool.add_node(pool.make_node(7))`), a nested read is fine, two
// `mut` arguments naming disjoint fields are not the same place, and a
// field path or an owning pointer is resolved after the arguments
// (`state.child.update(state.reset())` updates the child that exists then).
use std.box.Box

type Node { kind: i32 }

type Pool:
    nodes: List[Node]

impl Pool:
    mut fn add_node(node: Node) -> isize:
        self.nodes.push(node)
        self.nodes.len() - 1
    mut fn make_node(kind: i32) -> Node:
        self.nodes.push(Node { kind: 0 })
        Node { kind }
    fn count() -> isize: self.nodes.len()

fn add_node(mut pool: Pool, node: Node) -> isize:
    pool.nodes.push(node)
    pool.nodes.len() - 1

fn add_through(mut pool: Pool, node: Node) -> isize: add_node(pool, node)

type Pair { x: List[i32], y: List[i32] }

fn push_both(mut a: List[i32], mut b: List[i32]):
    a.push(5)
    b.push(6)

type Child { n: i32 }

impl Child:
    mut fn update(v: i32): self.n = self.n + v

type State:
    child: Child
    boxed: Box[Child]

impl State:
    mut fn reset() -> i32:
        self.child = Child { n: 100 }
        self.boxed = Box.new(Child { n: 200 })
        1

fn main:
    var pool = Pool { nodes: [] }
    let a = add_node(pool, Node { kind: 1 })
    let b = pool.add_node(Node { kind: pool.count() as i32 })
    let c = pool.add_node(pool.make_node(7))
    let d = add_through(mut pool, Node { kind: 2 })
    var p = Pair { x: [], y: [] }
    push_both(p.x, p.y)
    var s = State { child: Child { n: 1 }, boxed: Box.new(Child { n: 2 }) }
    s.child.update(s.reset())
    s.boxed.update(s.reset())
    print(f"{a} {b} {c} {d} {p.x[0]} {p.y[0]} {s.child.n} {s.boxed.n}")
