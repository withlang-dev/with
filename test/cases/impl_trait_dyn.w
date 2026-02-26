// Test trait object array (heterogeneous collection via dyn)
trait Animal =
    fn sound(self: Self) -> i32

type Dog = { bark_power: i32 }
type Cat = { purr_level: i32 }

impl Animal for Dog =
    fn sound(self: Dog) -> i32 = self.bark_power

impl Animal for Cat =
    fn sound(self: Cat) -> i32 = self.purr_level * 2

fn total_sound(a: dyn Animal, b: dyn Animal) -> i32 =
    a.sound() + b.sound()

fn main() -> i32 =
    let d = Dog { bark_power: 10 }
    let c = Cat { purr_level: 5 }
    let total = total_sound(d, c)
    println(total)
    0
