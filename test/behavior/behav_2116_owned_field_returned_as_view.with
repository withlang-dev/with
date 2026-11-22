//! expect-stdout: n a n n

// #2116: what stays legal. An owned field or element reached through a
// borrowed receiver or parameter is returned as a view of that argument.
type Holder { name: str, items: List[str] }

impl Holder:
    fn name_view(self: &Self) -> &str: self.name
    fn first(self: &Self) -> &str: self.items[0]

fn pick(h: &Holder) -> &str: h.name
fn of_param(s: &str) -> &str: s

fn main:
    let h = Holder { name: "n", items: ["a"] }
    print(f"{h.name_view()} {h.first()} {pick(h)} {of_param(h.name)}")
