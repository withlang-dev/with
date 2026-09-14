//! expect-stdout: ok

use pre_d_build_runner

// std.libc bindings a migrated test harness needs: qsort with a migrated
// comparator, and rand/srand (TommyDS's check.c, Phase 2).
fn main:
    let case_dir = p7_prepare_case("migrate_libc_qsort_rand", "migrate_libc_qsort_rand_test")
    p7_write(case_dir, "input.c", "#include <stdlib.h>\nstatic int by_int(const void* a, const void* b) { return *(const int*)a - *(const int*)b; }\nint sorted_first(void) { int v[5] = {5, 3, 9, 1, 7}; qsort(v, 5, sizeof(v[0]), by_int); return v[0] * 100 + v[4]; }\nint seeded(void) { srand(7); int a = rand(); srand(7); return a == rand(); }\n")
    p7_write(case_dir, "lib/.keep", "")
    let migrated = p7_run(case_dir, "libc_qsort_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/harness.w\0")
    p7_assert_success(migrated, "migrate qsort and rand through std.libc")
    p7_write(case_dir, "src/main.w", "use harness\nfn main:\n    assert(sorted_first() == 109)\n    assert(seeded() == 1)\n    print(\"libc ok\")\n")
    let executed = p7_run(case_dir, "libc_qsort_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run the migrated harness")
    assert(executed.stdout.contains("libc ok"))
    print("ok")
