@[target("aarch64")]
fn selected_target() -> i32: 64

@[target("x86_64")]
fn selected_target() -> i32: 86

fn main:
    assert(selected_target() == 86)
    print("target-spec-test-target: host path ran")
