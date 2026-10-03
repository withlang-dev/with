//! expect-stdout: n=3
//! expect-stdout: count=4
//! expect-stdout: n=5 at test/behavior/pipeline_stage_default_args.w:24:10
//! expect-stdout: n=6
//! expect-stdout: total=7

// #2024: a pipeline stage call is the call with the piped value first; the
// callee's default arguments fill what the stage leaves out, as they do for
// a direct call (Sema states the filled list; MIR lowers it). A `src()`
// default is the stage call's location. A call among the stage's
// arguments receives only its own arguments.

fn show(n: i32, label: &str = "n"):
    print(f"{label}={n}")

fn located(n: i32, loc: &str = src()):
    print(f"n={n} at {loc}")

fn label() -> str: "total"

fn main:
    3 |> show()
    4 |> show("count")
    5 |> located()
    6 |> show
    7 |> show(label())
