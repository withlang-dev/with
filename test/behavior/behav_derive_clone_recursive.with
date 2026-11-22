//! expect-stdout: [a, 2, [x]] [a, 2, [x, y]]
//! expect-stdout: (1 (2) (3)) (1 (2))

// `@[derive(Clone)]` on a type whose payload or field holds the type itself
// through a container (`List[Value]`, `List[Node]`): the derive's own check
// assumes the type is Clone while it runs, so the cycle through
// `List[Value]: Clone` closes. It refused: "variant 'Arr' payload of type
// 'List[Value]' does not implement Clone".
@[derive(Clone)]
enum Value:
    Str(s: str)
    Num(n: i64)
    Arr(items: List[Value])

fn show(v: &Value) -> str:
    match v:
        .Str(s) => s
        .Num(n) => f"{n}"
        .Arr(items) =>
            var out = "["
            for i in 0..items.len():
                if i > 0: out = out ++ ", "
                out = out ++ show(items[i])
            out ++ "]"

@[derive(Clone)]
type Node { label: i32, children: List[Node] }

fn show_node(n: &Node) -> str:
    var out = f"({n.label}"
    for c in n.children: out = out ++ " " ++ show_node(c)
    out ++ ")"

fn main:
    let v = Value.Arr([Value.Str("a"), Value.Num(2), Value.Arr([Value.Str("x")])])
    var w = v.clone()
    match w:
        .Arr(items) => items[2] = Value.Arr([Value.Str("x"), Value.Str("y")])
        _ => {}
    print(f"{show(v)} {show(w)}")
    let tree = Node { label: 1, children: [Node { label: 2, children: [] }, Node { label: 3, children: [] }] }
    var pruned = tree.clone()
    pruned.children.pop()
    print(f"{show_node(tree)} {show_node(pruned)}")
