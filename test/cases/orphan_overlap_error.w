//! expect-check-fail: overlapping implementations
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

trait Renderable:
    fn render(self: Self) -> str

impl Renderable for i32:
    fn render(self: i32) -> str:
        int_to_string(self)

trait Showable:
    fn show(self: Self) -> str

impl Showable for i32:
    fn show(self: i32) -> str:
        int_to_string(self)

// Blanket impl: anything Showable is also Renderable
// But i32 already has a direct impl of Renderable AND implements Showable
// This should be an overlap error
impl[T: Showable] Renderable for T:
    fn render(self: T) -> str:
        self.show()

fn main:
    print("ok")
