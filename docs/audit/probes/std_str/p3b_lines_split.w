use std.string

fn main:
    let l0 = lines("")
    print(f"lines_empty={l0.len()}")
    let l1 = lines("a\nb\nc")
    print(f"lines3={l1.len()} l0={l1.get(0)} l2={l1.get(2)}")
    let l2 = lines("a\n")
    print(f"lines_trail={l2.len()}")
    let l3 = lines("single")
    print(f"lines1={l3.len()} v={l3.get(0)}")
    let e = "".split(",")
    print(f"split_empty={e.len()}")
    let nd = "abc".split(",")
    print(f"split_nodelim={nd.len()} v={nd.get(0)}")
    let ed = "a,b,".split(",")
    print(f"split_traildelim={ed.len()} last=[{ed.get(ed.len() - 1)}]")
