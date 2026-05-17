//! expect-error: capability-bearing closure cannot escape into runtime code

use std.build

fn store_action(fs: ToolFs):
    let _action: fn(str) -> bool = path => fs.exists(path)
