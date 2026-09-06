use std.sync

fn wait(barrier: &Barrier) -> bool: barrier.wait()

fn main:
    let barrier = Barrier.new(1)
    no_suspend:
        let _ = wait(&barrier)
