//! expect-stdout: shown 3

// §9.5 (#1930): a field that shares its name with a global or a
// module-level function is not reached by its bare name (that is a
// shadowing error); `self.field` and the other declaration's qualified
// name stay valid. The prelude's `print` is std.builtins'.

use std.builtins

type Report {
    print: bool,
    count: i32,
}

impl Report:
    fn show:
        if self.print: builtins.print(f"shown {count}")

fn main:
    let r = Report { print: true, count: 3 }
    r.show()
