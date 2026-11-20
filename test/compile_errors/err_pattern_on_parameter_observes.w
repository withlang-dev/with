//! expect-check-fail: cannot consume read-only view binding `t`; clone it or transfer from the owner (a pattern observes a place: `match move x` takes `x` apart, §9.7)

// §9.7: a pattern on a by-value parameter observes it, so a binding it
// makes is a view and cannot be consumed; the error names the spelling
// that takes the parameter apart.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

enum Msg:
    Text(t: Tag)
    Empty

fn keep(t: Tag): print(t.name)

fn f(m: Msg):
    match m:
        .Text(t) => keep(t)
        .Empty => print("empty")

fn main: f(Msg.Text(Tag { name: "a" }))
