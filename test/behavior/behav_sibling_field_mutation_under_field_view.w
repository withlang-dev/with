//! expect-stdout: 4 1 10 2 3
// §3.8 / D22 (#1530 follow-up): a view of a field borrows that field's
// path, not its whole root. Writing a sibling field, or a sibling of an
// ancestor, while the view is live leaves the viewed value where it was, so
// it is accepted; only a write to the viewed path or one of its ancestors
// invalidates the view (err_assign_field_under_live_field_view,
// err_assign_parent_under_live_field_view).
type Inner { text: str, count: i32 }
type Lexer { source: str, pos: i32, inner: Inner, items: Vec[str] }
impl Lexer:
    mut fn scan() -> i32:
        let src = self.source
        self.pos = self.pos + 1
        self.inner.count = 10
        src.len() as i32
    mut fn nested() -> i32:
        let text = self.inner.text
        self.inner.count = self.inner.count + 1
        self.pos = self.pos + 1
        text.len() as i32
    mut fn element() -> i32:
        let first = self.items[0]
        self.pos = self.pos + 1
        self.inner.count = self.inner.count + 1
        first.len() as i32
fn main:
    var lx = Lexer { source: "ab" ++ "cd", pos: 0, inner: Inner { text: "x" ++ "y", count: 0 }, items: Vec.new() }
    lx.items.push("abc" ++ "")
    let n = lx.scan()
    let pos = lx.pos
    let count = lx.inner.count
    let t = lx.nested()
    let e = lx.element()
    print(f"{n} {pos} {count} {t} {e}")
