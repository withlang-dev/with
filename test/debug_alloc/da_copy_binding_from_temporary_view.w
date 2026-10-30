//! expect-debug-alloc: leak count=0
//! expect-stdout: docs|one-1|padded|hello|t42|7|1|2|one-1|zero
// A view into a statement temporary cannot outlive the statement, so a
// binding of one, or an unannotated function's return of one, takes the
// Copy value it views (a `str` under D111, a List
// under D120, plain bits): `let p = args()[1]` needs no `: str`. Before the
// copy, these were refused (#962, #2225, #2659); before the refusal, each
// read freed memory. Every shape is read after its temporary is gone and
// kept past it, and the allocator sees nothing freed twice or leaked.
use std.fs

fn names() -> List[str]:
    var xs: List[str] = List.new()
    xs.push("zero")
    xs.push(f"one-{xs.len()}")
    xs

fn lists() -> List[List[str]]:
    var outer: List[List[str]] = List.new()
    outer.push(names())
    outer

type Rec { title: str, n: i32 }

fn rec(): Rec { title: f"t{40 + 2}", n: 7 }

fn second(): names()[1]

fn first():
    let i = 0
    names()[i]

fn main:
    let line = "x\tdocs"
    let a = line.split("\t")[1]
    let b = names()[1]
    let c = (read_file("missing.txt") ?? "  padded  ").trim()
    let s = "hello world"
    let d = s.slice(0, 5).trim()
    let e = rec().title
    let n = rec().n
    let inner = lists()[0]
    var keep: List[str] = List.new()
    keep.push(a)
    keep.push(b)
    print(f"{a}|{b}|{c}|{d}|{e}|{n}|{inner.len() - 1}|{keep.len()}|{second()}|{first()}")
