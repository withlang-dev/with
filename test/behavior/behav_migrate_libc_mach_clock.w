//! only-on: darwin
//! expect-stdout: ok

use pre_d_build_runner

// Darwin's mach clock is modeled portably in std.libc (nanoseconds, timebase
// 1/1), so a harness migrated on macOS runs on every target; the migration
// itself needs <mach/mach_time.h>, hence darwin-only. The portable bindings
// run on every lane through the TommyDS check program (tommyds-test).
fn main:
    let case_dir = p7_prepare_case("migrate_libc_mach_clock", "migrate_libc_mach_clock_test")
    p7_write(case_dir, "input.c", "#include <mach/mach_time.h>\nunsigned long long elapsed_nonzero(void) { mach_timebase_info_data_t info; mach_timebase_info(&info); unsigned long long t = mach_absolute_time(); return (t / info.denom) * info.numer > 0; }\n")
    p7_write(case_dir, "lib/.keep", "")
    let migrated = p7_run(case_dir, "libc_mach_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/clock.w\0")
    p7_assert_success(migrated, "migrate the mach clock through std.libc")
    p7_write(case_dir, "src/main.w", "use clock\nfn main:\n    assert(elapsed_nonzero() == 1 as u64)\n    print(\"clock ok\")\n")
    let executed = p7_run(case_dir, "libc_mach_run", "run\0src/main.w\0")
    p7_assert_success(executed, "read the modeled clock")
    assert(executed.stdout.contains("clock ok"))
    print("ok")
