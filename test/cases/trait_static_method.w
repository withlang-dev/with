type Color = { r: i32, g: i32, b: i32 }

impl Color =
    fn red -> Color: Color { r: 255, g: 0, b: 0 }
    fn green -> Color: Color { r: 0, g: 255, b: 0 }
    fn blue -> Color: Color { r: 0, g: 0, b: 255 }
    fn brightness(self: Color) -> i32: self.r + self.g + self.b

fn main -> i32:
    let r = Color.red()
    let g = Color.green()
    let b = Color.blue()
    println(r.brightness())
    println(g.brightness())
    println(b.brightness())
