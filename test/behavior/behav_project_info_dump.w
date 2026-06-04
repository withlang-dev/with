//! args: --no-std --no-prelude --dump-project-info
//! expect-check-stdout: function path=test/behavior/behav_project_info_dump.w name=sample pub=1 params=1 return=i32

pub type Widget {
    value: i32,
}

pub fn sample(x: i32) -> i32:
    x

fn hidden -> i32:
    0

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    0
