type Config = {
    width: i32 = 80,
    height: i32 = 24,
    title: str = "untitled"
}

fn main -> i32:
    let c = Config {}
    println(c.width)
    println(c.height)
    println(c.title)
    let c2 = Config { width: 100 }
    println(c2.width)
    println(c2.height)
