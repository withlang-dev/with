use std.build

fn call_once(action: fn(str) -> bool) -> bool:
    action("with.toml")

fn direct_tool_closure(fs: ToolFs) -> bool:
    call_once(path => fs.exists(path))

fn main:
    print("ok")
