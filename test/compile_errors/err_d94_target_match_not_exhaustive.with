//! expect-error: the comptime match on `Target.os` does not name .Windows, .Wasi
// §17.5 (D94): a module-level comptime match is exhaustive, as every match
// is: a target with no arm would have no declarations.
comptime match Target.os:
    .Macos | .Linux =>
        fn name(): "unix"

fn main: print(name())
