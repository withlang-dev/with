async fn work() -> i32: 42

trait Runner:
    fn run(self: &Self) -> i32

type Suspender {}

impl Runner for Suspender:
    fn run(self: &Self) -> i32: work().await

fn invoke(runner: &dyn Runner) -> i32: runner.run()

fn main:
    let runner = Suspender {}
    no_suspend:
        let _ = invoke(&runner)
