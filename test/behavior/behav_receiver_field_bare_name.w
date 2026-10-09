//! expect-stdout: 3 3
//! expect-stdout: 4
//! expect-stdout: 15
//! expect-stdout: 3
//! expect-stdout: 8
//! expect-stdout: hi there
//! expect-stdout: 11
//! expect-stdout: 2 5
//! expect-stdout: 15
//! expect-stdout: 10

// §9.5 (#1930): in an instance method declared in its type's own module, a
// field of the receiver is in scope by its bare name; `self.field` remains
// valid. Receiver modes apply unchanged: `fn` reads, `mut fn` writes the
// receiver in place, `move fn` consumes it; a closure captures what
// `self.field` would (the `fn`-receiver closure case is #2025).

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

type Counter {
    count: i32,
    items: List[i32],
    step: fn(i32) -> i32,
    label: str,
}

impl Counter:
    fn both -> str: f"{count} {self.count}"
    mut fn bump:
        count += 1
    mut fn reset_to(n: i32):
        count = n
    fn total -> i32:
        var sum = 0
        for x in items: sum += x
        sum + count
    mut fn add(x: i32):
        items.push(x)
    fn item_count -> i32: items.len() as i32
    mut fn plus_count(x: i32) -> i32: apply(y => y + count, x)
    fn greet(name: &str) -> str: f"{label} {name}"
    // A bare callee names the field: it calls the field's value.
    fn stepped -> i32: step(count)
    // Struct-literal shorthand reads the field.
    fn copy_of -> Counter: Counter { count, items: items.clone(), step: x => x * 3, label: label }
    move fn into_count -> i32: apply(y => y * count, 2)

type Pair[T] {
    first: T,
    second: T,
}

impl[T: Copy + Display] Pair[T]:
    fn show -> str: f"{first} {second}"
    mut fn swap:
        let t: T = first
        first = second
        second = t

fn main:
    var c = Counter { count: 3, items: [1, 2], step: x => x * 2, label: "hi" }
    print(c.both())
    c.bump()
    print(f"{c.count}")
    c.add(7)
    c.reset_to(5)
    print(f"{c.total()}")
    print(f"{c.item_count()}")
    print(f"{c.plus_count(3)}")
    print(c.greet("there"))
    print(f"{c.stepped() + 1}")
    var p = Pair { first: 5, second: 2 }
    p.swap()
    print(p.show())
    let d = c.copy_of()
    print(f"{d.stepped()}")
    print(f"{d.into_count()}")
