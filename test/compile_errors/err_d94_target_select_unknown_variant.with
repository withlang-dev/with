//! expect-error: `OsKind` has no variant `.Freebsd`
// §17.5 (D94): a target variant is one std.os declares.
comptime if Target.os == .Freebsd:
    fn name(): "bsd"
else:
    fn name(): "other"

fn main: print(name())
