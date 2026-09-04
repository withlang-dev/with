use std.sync

fn init(): ()
fn call(once: &Once): once.call_once(init)

fn main:
    let once = Once.new()
    no_suspend:
        call(&once)
