type Child = {
    items: Vec[str],
}

impl Child
    fn add(self: Child, s: str):
        self.items.push(s)

type Parent = {
    child: Child,
}

impl Parent
    fn add(self: Parent, s: str):
        self.child.add(s)

fn main -> i32:
    let mut p = Parent {
        child: Child {
            items: Vec.new(),
        },
    }
    p.add("abc")
    if p.child.items.len() == 1 then 0 else 1
