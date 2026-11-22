//! expect-error: shadowing is not allowed for 'name': it names a field of the receiver `Person`, which this method reaches by its bare name (§9.5)

// §9.5 (#1930), §29.8: a parameter named like a receiver field would shadow
// the field this method reaches by its bare name.

type Person {
    name: str,
}

impl Person:
    mut fn rename(name: str):
        self.name = name

fn main:
    var p = Person { name: "a" }
    p.rename("b")
    print(p.name)
