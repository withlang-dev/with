//! expect-stdout: 42
//! expect-stdout: 42
//! expect-stdout: 7
//! expect-stdout: 9
//! expect-stdout: 5

// §18.1 (#1930): a module names itself by the last segment of its module
// path — the `module` header's, else the file's stem — and `name.decl`
// reaches its own declaration `decl`, whatever shadows the bare name: a
// local, a receiver field (§9.5). The bare self-name names nothing.

use selfname.main
use selfname.headed

fn f -> i32: 7

type Holder {
    f: i32,
}

impl Holder:
    // field `f` and this module's fn `f`
    fn both -> i32: self.f + behav_self_name_qualifies.f()

fn main:
    print(f"{main_module_answer()}")
    print(f"{headed_answer()}")
    print(f"{behav_self_name_qualifies.f()}")
    print(f"{Holder { f: 2 }.both()}")
    let f = 5
    print(f"{f}")
