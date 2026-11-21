//! expect-stdout: [a, [b, c]]
//! expect-stdout: XXX

// D143 with #3483 and #3508: in the open pass over a self-calling function
// with an inferred return type, a call of the function itself reads
// `Never`. A method declared for one instantiation (`List[str].join`,
// `Box[str].shout`) is then called on a `List[Never]` or a `Box[Never]`;
// that is not the wrong instantiation, it is one not typed yet, and the
// pass that follows checks the real one. The JSON example joins its own
// results this way.
enum Tree {
    Leaf(str)
    | Node(List[Tree])
}

fn show(t: &Tree):
    match t:
        .Leaf(s) => s ++ ""
        .Node(kids) => "[" ++ [show(k) for k in kids].join(", ") ++ "]"

type Box[T] { v: T }

impl Box[str]:
    fn shout() -> str: self.v.to_upper()

fn nest(n: i32):
    if n == 0: "x" else: Box { v: nest(n - 1) ++ "x" }.shout()

fn main:
    print(show(Tree.Node([Tree.Leaf("a"), Tree.Node([Tree.Leaf("b"), Tree.Leaf("c")])])))
    print(nest(2))
