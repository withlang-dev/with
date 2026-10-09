//! expect-stdout: ok

extend i32:
    mut fn bump_and_get() -> i32:
        self += 1
        self

type Factory { made: i32 }

type Holder { values: List[i32] }

type Viewed { value: i32 }

impl Factory:
    mut fn make_value() -> List[i32]:
        self.made += 1
        let value: List[i32] = List.new()
        value |> push(42)
        value

impl Holder:
    mut fn take_values() -> List[i32]: return move self.values

impl Viewed:
    mut fn value_ref() -> &i32: &self.value

fn main:
    var n = 40
    let copied = n.bump_and_get()
    assert(n == 41)
    assert(copied == 41)

    var factory = Factory { made: 0 }
    let independent = factory.make_value()
    assert(factory.made == 1)
    assert(independent[0] == 42)

    var holder = Holder { values: List[i32].new() |> push(42) }
    let taken = holder.take_values()
    assert(taken[0] == 42)
    assert(holder.values.len() == 0)

    var viewed = Viewed { value: 42 }
    let view = viewed.value_ref()
    assert(*view == 42)
    print("ok")
