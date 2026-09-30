//! expect-stdout: ok

// #1911: glibc's assert is `((void) sizeof ((e) ? 1 : 0), __extension__ ({
// if (e) ; else __assert_fail (...); }))`. The migrator dropped the right
// operand of that comma (a failed lowering merged as an empty one), so a
// failed assert ran on. The same shapes, spelled here so every target's
// headers are out of it: a discarded comma, a GNU statement expression under
// `__extension__`, and a discarded operator whose operands call functions.
use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_discarded_effects", "discarded_effects_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "#include <stdlib.h>\nstatic int hits;\nstatic int calls;\nstatic int count(void) { return ++calls; }\n#define MUST(e) ((void) sizeof ((e) ? 1 : 0), __extension__ ({ if (e) ; else abort (); }))\n#define BUMP() ((void) 0, __extension__ ({ hits += 1; }))\nint bump_twice(void) { BUMP(); BUMP(); return hits; }\nint discard_sum(void) { (void) (count() + count()); (void) -count(); return calls; }\nint must_hold(int n) { MUST(n == 1); return n; }\nint must_fail(void) { MUST(0); return 99; }\n")
    let migrated = p7_run(case_dir, "discarded_effects_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/discarded_effects.w\0")
    p7_assert_success(migrated, "migrate discarded commas, statement expressions and operator operands")
    p7_write(case_dir, "src/main.w", "use discarded_effects\nfn main:\n    assert(bump_twice() == 2)\n    assert(discard_sum() == 3)\n    assert(must_hold(1) == 1)\n    print(\"effects ok\")\n")
    let executed = p7_run(case_dir, "discarded_effects_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run every discarded side effect")
    assert(executed.stdout.contains("effects ok"))
    p7_write(case_dir, "src/main.w", "use discarded_effects\nfn main: must_fail()\n")
    let failed = p7_run(case_dir, "discarded_effects_fail", "run\0src/main.w\0")
    assert(failed.rc != 0)
    print("ok")
