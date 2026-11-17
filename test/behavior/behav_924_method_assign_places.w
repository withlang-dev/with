//! expect-stdout: 3 12
//! expect-stdout: 14 1 1

// #924 (§4.2.5): `x .= f(args)` over a resource and over a user
// `IndexPlace`. A consuming method takes the old value and the result lands
// in its place; a reading method's old value is dropped at the store. The
// subscript of a user place is evaluated once, read through `get` and
// stored through `set`.
var drops = 0

type Res { id: i32 }

impl Drop for Res:
    move fn drop(): drops += 1

impl Res:
    move fn next() -> Res: Res { id: self.id + 1 }
    fn bumped() -> Res: Res { id: self.id + 10 }

fn run() -> i32:
    var r = Res { id: 1 }
    r .= next()
    r .= bumped()
    r.id

type Counts { names: List[str], values: List[i32] }

impl Counts:
    fn slot_of(key: &str) -> isize:
        for i in 0..self.names.len():
            if self.names[i] == key: return i
        -1

impl IndexPlace[str, i32] for Counts:
    fn get(self: &Self, key: str) -> i32:
        let i = self.slot_of(key)
        if i < 0: 0 else: self.values[i]

    mut fn set(key: str, value: i32):
        let i = self.slot_of(key)
        if i < 0:
            self.names.push(key)
            self.values.push(value)
        else:
            self.values[i] = value

var keys = 0

fn key() -> str:
    keys += 1
    "a"

fn main:
    let id = run()
    print(f"{drops} {id}")
    var c = Counts { names: List.new(), values: List.new() }
    c["a"] = 7
    c[key()] .= max(14)
    print(f"{c["a"]} {keys} {c.names.len()}")
