//! expect-stdout: ok

use pre_d_build_runner

fn allocations(report: &str):
    var count = 0
    for line in report.split("\n"):
        if line.starts_with("ALLOC "):
            assert(line.split(" ").len() == 4)
            count = count + 1
    count

fn main:
    let case_dir = p7_prepare_case("allocation_trace", "allocation_trace")
    let source = "let values: Vec[i32] = Vec.new()\nvalues.push(42)\nprint(values[0])\n"
    p7_write(case_dir, "src/main.w", source)
    let ordinary = p7_run(case_dir, "ordinary", "run\0src/main.w\0")
    p7_assert_success(ordinary, "ordinary allocation fixture")
    assert(ordinary.stdout == "42\n" and allocations(ordinary.stderr) == 0)
    let traced = p7_run(case_dir, "traced", "run\0--trace-alloc\0src/main.w\0")
    p7_assert_success(traced, "allocation trace without leak ledger")
    assert(traced.stdout == ordinary.stdout and allocations(traced.stderr) > 0)
    let checked = p7_run(case_dir, "checked", "run\0--trace-alloc\0--debug-alloc\0src/main.w\0")
    p7_assert_success(checked, "allocation trace with leak ledger")
    assert(checked.stdout == ordinary.stdout and allocations(checked.stderr) > 0)
    assert(not checked.stderr.contains("LEAK") and not checked.stderr.contains("DOUBLE-FREE"))
    let evaluated = p7_run(case_dir, "evaluated", "--trace-alloc\0-e\0" ++ source ++ "\0")
    p7_assert_success(evaluated, "allocation trace one-liner flag")
    assert(evaluated.stdout == ordinary.stdout and allocations(evaluated.stderr) > 0)
    print("ok")
