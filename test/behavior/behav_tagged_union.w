//! expect-stdout: ok

// Tests: tagged unions (enums with payloads), nested payloads,
//        multiple payload types, match destructuring

enum Value {  | IntVal(i32) }
    | FloatVal(f64)
    | BoolVal(bool)
    | NoneVal

fn value_to_int(v: Value) -> i32:
    match v
        .IntVal(i) => i
        .FloatVal(f) => f as i32
        .BoolVal(b) => if b: 1 else: 0
        .NoneVal => -1

fn test_tagged_union_int:
    let v = Value.IntVal(42)
    assert(value_to_int(v) == 42)

fn test_tagged_union_float:
    let v = Value.FloatVal(3.7)
    assert(value_to_int(v) == 3)

fn test_tagged_union_bool:
    let v = Value.BoolVal(true)
    assert(value_to_int(v) == 1)
    let v2 = Value.BoolVal(false)
    assert(value_to_int(v2) == 0)

fn test_tagged_union_none:
    let v = Value.NoneVal
    assert(value_to_int(v) == -1)

fn is_int_val(v: Value) -> bool:
    match v
        .IntVal(_) => true
        _ => false

fn test_tagged_union_discriminant:
    assert(is_int_val(Value.IntVal(0)))
    assert(not is_int_val(Value.FloatVal(0.0)))
    assert(not is_int_val(Value.NoneVal))

enum Message {  | Quit }
    | Echo(str)
    | Move(x: i32, y: i32)

fn handle_message(msg: Message) -> str:
    match msg
        .Quit => "quit"
        .Echo(s) => s
        .Move(x, y) => "move"

fn test_message_variants:
    assert(handle_message(Message.Quit) == "quit")
    assert(handle_message(Message.Echo("hello")) == "hello")
    assert(handle_message(Message.Move(1, 2)) == "move")

enum Tree { Leaf(i32) | Node(i32) }

fn tree_value(t: Tree) -> i32:
    match t
        .Leaf(v) => v
        .Node(v) => v

fn test_tree:
    assert(tree_value(Tree.Leaf(5)) == 5)
    assert(tree_value(Tree.Node(10)) == 10)

fn main:
    test_tagged_union_int()
    test_tagged_union_float()
    test_tagged_union_bool()
    test_tagged_union_none()
    test_tagged_union_discriminant()
    test_message_variants()
    test_tree()
    println("ok")
