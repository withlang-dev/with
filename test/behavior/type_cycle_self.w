//! expect-error: dependency loop

type Node {
    child: Node,
}

fn main:
    println("should not compile")
