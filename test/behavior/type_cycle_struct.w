//! expect-error: dependency loop

type Node {
    parent: Tree,
}

type Tree {
    root: Node,
}

fn main:
    println("should not compile")
