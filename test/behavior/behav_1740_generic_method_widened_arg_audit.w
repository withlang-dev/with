//! expect-stdout: ok

// #1740 (D6: one FnAbi, read by caller and callee): an i32 argument that
// widens into a generic method's `i64` parameter (BTreeMap.key_at's index,
// a user `Bag[T].shift(k: i64)`) reached the call at its source width; the
// generic-call marshal recorded it unconverted and `analyze audit:all`
// reported "marshaled LLVM type disagrees with FnAbi". The value is now
// widened to the parameter's own type where it is marshaled.
use pre_d_build_runner

fn program_text -> str:
    "use std.collections.{BTreeMap}\n" ++
        "type Bag[T] { items: List[T] }\n" ++
        "impl[T] Bag[T]:\n" ++
        "    fn shift(k: i64) -> i64: k * 2\n" ++
        "    fn run() -> i64:\n" ++
        "        var i = 0\n" ++
        "        i = i - 3\n" ++
        "        let lens = self.items.len() as i32\n" ++
        "        self.shift(i) + self.shift(lens)\n" ++
        "fn main:\n" ++
        "    let b: Bag[i64] = Bag { items: [1, 2] }\n" ++
        "    let names: BTreeMap[i32, str] = [x: (if x == 1: \"ten\" else: \"thirty\") for x in 0i32..4 if x > 0]\n" ++
        "    var text = \"map\"\n" ++
        "    for (k, v) in names:\n" ++
        "        text = text ++ f\" {k}:{v}\"\n" ++
        "    print(f\"{b.run()} {text}\")\n"

fn main:
    let case_dir = p7_prepare_case("generic_method_widened_arg_audit", "generic_method_widened_arg_audit")
    p7_write(case_dir, "src/main.w", program_text())
    let ran = p7_run(case_dir, "widened_run", "run\0src/main.w\0")
    p7_assert_success(ran, "widened generic-method arguments run")
    assert(ran.stdout.contains("-2 map 1:ten 2:thirty 3:thirty"))
    let audited = p7_run(case_dir, "widened_audit", "analyze\0src/main.w\0audit:all\0")
    p7_assert_success(audited, "audit:all over widened generic-method arguments")
    assert(audited.stdout.contains("violations=0"))
    print("ok")
