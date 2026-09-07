use std.sync

fn init(): ()

fn main:
    let once = Once.new()
    no_suspend:
        once.call_once(init)
