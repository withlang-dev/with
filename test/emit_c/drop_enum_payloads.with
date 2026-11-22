//! expect-debug-alloc: leak count=0
//! expect-stdout: 6
//! expect-stdout: text: abc
//! expect-stdout: words: 2
//! expect-stdout: none
//! expect-stdout: err bad

// #983: an enum drops its live variant's payloads (a str, a List, a Box of
// a recursive node); Option and Result likewise. Every allocation is
// freed exactly once.
use std.box.Box

enum Value:
    Num(i64)
    Text(str)
    Words(List[str])

type Node:
    value: i64
    next: Option[Box[Node]]

fn chain(n: i64) -> Option[Box[Node]]:
    if n == 0: return None
    Some(Box.new(Node { value: n, next: chain(n - 1) }))

fn sum(node: &Option[Box[Node]]) -> i64:
    match node:
        Some(b) => b.value + sum(&b.next)
        None => 0

fn describe(v: &Value) -> str:
    match v:
        Value.Num(n) => f"num: {n}"
        Value.Text(s) => f"text: {s}"
        Value.Words(ws) => f"words: {ws.len()}"

fn parse(s: &str) -> Result[i64, str]:
    if s == "bad": return Err("err " ++ s)
    Ok(1)

fn main:
    let list = chain(3)
    print(sum(&list))
    let values = [Value.Text("ab" ++ "c"), Value.Words(["x", "y"]), Value.Num(4)]
    print(describe(&values[0]))
    print(describe(&values[1]))
    let empty: Option[str] = None
    print(empty ?? "none")
    match parse("bad"):
        Ok(n) => print(n)
        Err(e) => print(e)
