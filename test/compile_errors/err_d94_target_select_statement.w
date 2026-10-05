//! expect-error: an arm of a module-level comptime selection holds declarations, not statements
// §17.5 (D94): an arm selects declarations; a statement belongs in a function.
fn main: print("x")

comptime if Target.os == .Linux:
    print("linux")
else:
    fn helper(): 1
