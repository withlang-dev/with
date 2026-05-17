//! expect-stdout: ok

type PipeBox {
    value: i32,
}

fn PipeBox.add(self: PipeBox, n: i32) -> PipeBox:
    PipeBox { value: self.value + n }

fn PipeBox.choose(self: PipeBox) -> i32:
    1

fn choose(_box: PipeBox) -> i32:
    2

fn plus_one(x: i32) -> i32:
    x + 1

fn add_i32(x: i32, y: i32) -> i32:
    x + y

fn test_vec_methods_in_pipeline:
    var v: Vec[str] = Vec.new()
    v |> push("a")
    v |> push("b")
    assert((v |> len()) == 2)
    assert((v |> get(0)) == "a")
    assert((v |> get(1)) == "b")

fn test_string_methods_in_pipeline:
    assert(("hello" |> to_upper()) == "HELLO")
    assert(("  hi  " |> trim()) == "hi")

fn test_user_methods_in_pipeline:
    let box = PipeBox { value: 1 } |> add(2) |> add(3)
    assert(box.value == 6)

fn test_free_function_pipeline_still_works:
    assert((41 |> plus_one) == 42)
    assert((40 |> add_i32(2)) == 42)

fn test_method_wins_over_free_function:
    let box = PipeBox { value: 10 }
    assert((box |> choose()) == 1)

fn main:
    test_vec_methods_in_pipeline()
    test_string_methods_in_pipeline()
    test_user_methods_in_pipeline()
    test_free_function_pipeline_still_works()
    test_method_wins_over_free_function()
    print("ok")
