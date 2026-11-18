//! expect-check-fail: capability requires an explicit binding name, e.g. 'as ctx'

// #490 (§17.1b): the shorthand is for a capability with a standard default binding.
type Foo { n: i32 }
comptime with Foo:
fn f() -> i32: 0
fn main: ()
