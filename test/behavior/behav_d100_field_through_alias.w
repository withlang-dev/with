//! expect-stdout: ok

use pre_d_build_runner

// D100 (§18.3, #2209): an alias names a type its declaration owns, so the
// declaration's `pub` fields stay `pub` across a package boundary however
// the type is spelled, and its private ones stay private. The alias once
// took over the type's declaring node (std.libc's
// `mach_timebase_info_data_t` hid every field of `mach_timebase_info`).
fn main:
    let case_dir = p7_prepare_case("d100_field_through_alias", "d100_field_through_alias_test")
    p7_write(case_dir, "lib/with.toml", "[package]\nname = \"clock\"\n")
    p7_write(case_dir, "lib/clock.w", "pub type Timebase { pub numer: u32 = 0, pub denom: u32 = 0, epoch: u32 = 0 }\npub type timebase_t = Timebase\n")
    p7_write(case_dir, "src/main.w", "use clock\nfn main:\n    let t = Timebase { numer: 3, denom: 4 }\n    let u: timebase_t = timebase_t { numer: 5, denom: 6 }\n    assert(t.numer + u.denom == 9)\n")
    let read = p7_run(case_dir, "pub_fields_through_alias", "run\0src/main.w\0")
    p7_assert_success(read, "an alias in the declaring package leaves pub fields readable")
    p7_write(case_dir, "src/main.w", "use clock\nfn main:\n    let t = timebase_t { numer: 1 }\n    assert(t.epoch == 0)\n")
    let refused = p7_run(case_dir, "private_field_through_alias", "check\0src/main.w\0")
    assert(refused.rc != 0)
    assert(refused.stderr.contains("field 'Timebase.epoch' is private to its package"))
    print("ok")
