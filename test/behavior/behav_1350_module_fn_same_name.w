//! expect-stdout: ok

// #1350: a top-level fn name declared by several modules resolves per
// module — the root, displaced_fn_owner and displaced_fn_importer each bind
// their own `label`, the owner's calls bind its own is_digit/pick/twice
// (direct, as a value, through a pipeline, inside a generic call, beside a
// local of the same name), and the importer binds the owner's pub is_digit,
// never the root's. The flat merge used to drop the imported modules'
// declarations for the root's, which broke their own calls ("symbol
// 'is_digit' is not visible from this module").
use displaced_fn_owner
use displaced_fn_importer

fn is_digit(ch: u8) -> bool: ch > 1
fn pick(a: i32, b: i32) -> i32: a
fn twice(x: i32) -> i32: x + 1000
fn label() -> str: "root"

fn main:
    assert(is_digit(5) and pick(1, 2) == 1 and twice(1) == 1001 and label() == "root")
    assert(not via_value(33) and via_value(50))
    assert(via_pipe(50) and not via_pipe(33))
    assert(local_named(1) == 101)
    assert(generic_own(3) == 6)
    assert(owner_label() == "owner" and importer_label() == "importer")
    assert(not importer_is_digit(33) and importer_is_digit(57))
    var xs: Vec[i32] = Vec.new()
    xs.push(48)
    xs.push(33)
    xs.push(57)
    assert(count_digits(&xs) == 2)
    print("ok")
