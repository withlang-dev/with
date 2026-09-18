type GBox[T] { value: T }

impl[T] GBox[T]:
    fn get(): self.value

fn main:
    let generic_box = GBox { value: 42 }
    assert(generic_box.get() == 42)
