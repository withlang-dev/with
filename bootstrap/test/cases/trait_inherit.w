// Test trait with multiple implementations
trait Serializable =
    fn serialize(self: Self) -> i32

type User = { id: i32, age: i32 }
type Product = { price: i32 }

impl Serializable for User =
    fn serialize(self: User) -> i32: self.id + self.age

impl Serializable for Product =
    fn serialize(self: Product) -> i32: self.price

fn save[T: Serializable](item: T) -> void:
    let data = item.serialize()
    println(data)

fn save_dyn(item: dyn Serializable) -> void:
    println(item.serialize())

fn main -> i32:
    let u = User { id: 1, age: 25 }
    let p = Product { price: 99 }
    // Static dispatch via trait bounds
    save(u)
    save(p)
    // Dynamic dispatch via dyn
    save_dyn(u)
    save_dyn(p)
    0
