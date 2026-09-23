//! expect-stdout: ok

// #1413: a Range's inclusive flag is a `bool` field. Codegen laid the Range
// struct out as {Elem, Elem, i8} while MIR typed the flag place `bool` (i1),
// so `analyze audit:all` failed on every program that iterates a stored
// range: "projection lowers to LLVM type i8 but its MIR type 13 (bool) lowers
// to i1". The flag lowers like every bool field now, in the same one byte.
use pre_d_build_runner

fn ranges_text -> str:
    "fn count(r: Range[i32]) -> i32:\n" ++
        "    var n = 0\n" ++
        "    for _ in r:\n" ++
        "        n += 1\n" ++
        "    n\n" ++
        "fn count_inclusive(r: RangeInclusive[i32]) -> i32:\n" ++
        "    var n = 0\n" ++
        "    for _ in r:\n" ++
        "        n += 1\n" ++
        "    n\n" ++
        "fn main:\n" ++
        "    let half = 2..7\n" ++
        "    let closed = 2..=7\n" ++
        "    assert(count(half) == 5)\n" ++
        "    assert(count_inclusive(closed) == 6)\n" ++
        "    assert(4 in half and not (7 in half) and 7 in closed)\n" ++
        "    print(\"ranges ok\")\n"

fn main:
    let case_dir = p7_prepare_case("range_flag_audit", "range_flag_audit")
    p7_write(case_dir, "src/ranges.w", ranges_text())
    let ran = p7_run(case_dir, "ranges_run", "run\0src/ranges.w\0")
    p7_assert_success(ran, "stored ranges run")
    assert(ran.stdout.contains("ranges ok"))
    let audited = p7_run(case_dir, "ranges_audit", "analyze\0src/ranges.w\0audit:all\0")
    p7_assert_success(audited, "audit:all over stored ranges")
    assert(audited.stdout.contains("violations=0"))
    print("ok")
