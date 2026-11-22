//! expect-stdout: ok

type Switch { value: i32 }

impl Switch:
    mut fn stop() -> Never: unreachable()
    mut fn after_stop(_required: i32): self.value = 99

fn after_stop(_value: Never) -> Never: unreachable()

fn main:
    var s = Switch { value: 42 }
    if false:
        // Never is not Unit and does not thread the receiver. The next stage
        // therefore resolves as the free function over Never, not the Switch
        // method (whose required argument would make this expression invalid).
        s |> stop() |> after_stop()
    assert(s.value == 42)
    print("ok")
