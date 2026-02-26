// Associated types in trait declarations and impl blocks
trait Container =
    type Item
    fn first(self: &Self) -> i32

type IntList = { data: i32, len: i32 }

impl Container for IntList
    type Item = i32
    fn first(self: &IntList) -> i32: self.data

// Associated type with default in trait
trait Printable =
    type Output = str
    fn to_output(self: &Self) -> str

type Label = { text: str }

impl Printable for Label
    type Output = str
    fn to_output(self: &Label) -> str: self.text

// Associated type in plain impl block
type Point = { x: i32, y: i32 }

impl Point
    type Dim = i32
    fn sum(self: &Point) -> i32: self.x + self.y

fn main -> i32:
    let list = IntList { data: 42, len: 1 }
    println(list.first())
    let p = Point { x: 10, y: 20 }
    println(p.sum())
    if list.first() == 42 and p.sum() == 30 then 0 else 1
