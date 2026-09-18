type Pt:
    x: i32
    y: i32

fn tag(p: Pt) -> str:
    match p:
        Pt { x: 1, y: 2 } => "one-two"
        _ => "other"

fn main:
    print(tag(Pt { x: 1, y: 2 }))
    print(tag(Pt { x: 9, y: 9 }))
