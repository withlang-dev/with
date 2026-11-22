//! expect-stdout: ok

fn parse(text: str) -> Result[i32, str]:
    if text == "good":
        Ok(21)
    else:
        Err("bad")

fn option_pipeline(value: Option[i32]) -> i32:
    value |> match:
        Some(x) => x + 1
        None => 0

fn result_pipeline(text: str) -> i32:
    text |> parse |> match:
        Ok(v) => v * 2
        Err(_) => -1

fn inline_pipeline(value: Option[i32]) -> i32:
    value |> match { Some(x) => x, None => 0 }

fn main:
    assert(option_pipeline(Some(3)) == 4)
    assert(option_pipeline(None) == 0)
    assert(result_pipeline("good") == 42)
    assert(result_pipeline("bad") == -1)
    assert(inline_pipeline(Some(9)) == 9)
    print("ok")
