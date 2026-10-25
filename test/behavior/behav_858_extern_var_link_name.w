//! expect-stdout: true
//! skip-on: windows environ is _environ in the CRT and is not a link-time global of every Windows libc
// #858: @[link_name("sym")] names the C symbol an extern var links against,
// as it does on an extern fn. It was dropped: the object referenced the
// With name, so this program failed to link ("undefined symbol
// _process_environment").
@[link_name("environ")]
extern var process_environment: *mut *mut u8

fn main:
    print(process_environment != null)
