//! expect-stdout: ok

use pre_d_build_runner

// A pointer to a function TYPEDEF (`typedef int cmp_fn(const void*, const
// void*); cmp_fn* cmp`) is the function pointer, in a field, a parameter
// and an assignment alike (TommyDS's tommy_compare_func*, Phase 2).
fn main:
    let case_dir = p7_prepare_case("migrate_fn_typedef_pointer", "migrate_fn_typedef_pointer_test")
    p7_write(case_dir, "input.c", "typedef int cmp_fn(const void* a, const void* b);\nstruct holder { cmp_fn* cmp; int pad; };\nstatic int by_int(const void* a, const void* b) { return *(const int*)a - *(const int*)b; }\nvoid holder_init(struct holder* h, cmp_fn* cmp) { h->cmp = cmp; h->pad = 0; }\nint holder_compare(struct holder* h, int a, int b) { return h->cmp(&a, &b); }\nint order(int a, int b) { struct holder h; holder_init(&h, by_int); return holder_compare(&h, a, b); }\n")
    p7_write(case_dir, "lib/.keep", "")
    let migrated = p7_run(case_dir, "fn_typedef_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/holder.w\0")
    p7_assert_success(migrated, "migrate a pointer to a function typedef as a function pointer")
    p7_write(case_dir, "src/main.w", "use holder\nfn main:\n    assert(order(3, 5) < 0 and order(5, 3) > 0 and order(4, 4) == 0)\n    print(\"typedef ok\")\n")
    let executed = p7_run(case_dir, "fn_typedef_run", "run\0src/main.w\0")
    p7_assert_success(executed, "call through the stored comparator")
    assert(executed.stdout.contains("typedef ok"))
    print("ok")
