// Test implementing multiple traits for the same type
trait Drawable =
    fn draw(self: Self) -> str

trait Clickable =
    fn click(self: Self) -> i32

type Button = { label: str, id: i32 }

impl Drawable for Button =
    fn draw(self: Button) -> str: self.label

impl Clickable for Button =
    fn click(self: Button) -> i32: self.id

fn render(d: dyn Drawable) -> void:
    println(d.draw())

fn handle(c: dyn Clickable) -> void:
    println(c.click())

fn main -> i32:
    let btn = Button { label: "Submit", id: 42 }
    render(btn)
    handle(btn)
    0
