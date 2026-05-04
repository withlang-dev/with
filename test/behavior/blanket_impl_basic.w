//! expect-stdout: ok

trait Showable:
    fn show(self: &Self) -> str

impl Showable for i32:
    fn show(self: i32) -> str:
        int_to_string(self)

// Blanket impl: anything Showable is also Displayable
trait Displayable:
    fn display(self: &Self) -> str

impl[T: Showable] Displayable for T:
    fn display(self: T) -> str:
        self.show()

// Generic function requiring Displayable bound — should pass for i32
// because i32: Showable, and blanket impl gives i32: Displayable
fn check_displayable[T: Displayable](x: T) -> i32:
    1

fn main:
    let x: i32 = 42
    assert(check_displayable(x) == 1)
    print("ok")
