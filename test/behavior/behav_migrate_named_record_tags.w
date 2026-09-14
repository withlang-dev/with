//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_named_record_tags", "record_tags_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "typedef struct _Pair { int key; int value; } Pair;\ntypedef struct __Nested { Pair pair; } Nested;\ntypedef union _Choice { int value; float other; } Choice;\nPair make_pair(void) { Pair pair = {17, 25}; return pair; }\nint total(void) { Nested nested = {{17, 25}}; Choice choice = {42}; Pair pair = make_pair(); return nested.pair.key + nested.pair.value + choice.value + pair.key + pair.value; }\n")
    let migrated = p7_run(case_dir, "record_tags_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/record_tags.w\0")
    p7_assert_success(migrated, "migrate named record tags beginning with underscores")
    p7_write(case_dir, "src/main.w", "use record_tags\nfn main:\n    assert(total() == 126)\n    print(\"records ok\")\n")
    let executed = p7_run(case_dir, "record_tags_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run migrated record initializers and aggregate returns")
    assert(executed.stdout.contains("records ok"))
    print("ok")
