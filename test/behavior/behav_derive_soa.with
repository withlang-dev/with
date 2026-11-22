//! expect-stdout: ok

@[derive(SoA)]
type Transform {
    x: i32,
    y: i32,
    name: str,
}

fn main:
    var transforms = TransformSoA.new()
    transforms = transforms.push(Transform { x: 1, y: 2, name: "first" })
    transforms = transforms.push(Transform { x: 3, y: 4, name: "second" })

    assert(transforms.len() == 2)

    let first = transforms.get(0)
    assert(first.x == 1)
    assert(first.y == 2)
    assert(first.name == "first")

    let second = transforms.get(1)
    assert(second.x == 3)
    assert(second.y == 4)
    assert(second.name == "second")

    print("ok")
