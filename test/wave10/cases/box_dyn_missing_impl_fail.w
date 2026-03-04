trait Speak =
    fn speak(self: Self) -> i32

type Rock = { n: i32 }

fn call_box(x: Box[dyn Speak]) -> i32:
    x.speak()

fn main -> i32:
    let r = Rock { n: 1 }
    call_box(r)
