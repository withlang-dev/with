//! expect-stdout: 2000 2000 65536 3 10462
// §9.1b (D95, #2101): a `pub const` takes its type from its value, as a
// private one does; an unsuffixed one has no numeric type of its own, so
// each use types it (§4.2.1).
pub const ENEMY_CAP = 2000
pub const SIZE = 64 * 1024
pub const NAMES = ["WARDEN", "LANCER", "HIVE"]
pub const VENDOR = 0x28DEu16

fn wide(n: i64): n
fn narrow(n: i32): n
fn scale(x: f32): x

fn main:
    print(f"{wide(ENEMY_CAP)} {narrow(ENEMY_CAP)} {SIZE} {NAMES.len()} {VENDOR}")
    assert(scale(ENEMY_CAP) == 2000.0)
