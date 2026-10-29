//! expect-stdout: ok

use pre_d_build_runner

// A `for` over `xs.into_iter()` as an arm of an `if` is a loop, of type
// Unit. demand_generic_iter_next stamped the iterator's next() result type
// on the `for` node and, when the node had none before, never removed it:
// Sema read the arm as `Option[T]` while MIR lowered a loop
// (audit:resolution: "MIR Unit, Sema Option[PlVal]").
fn main:
    let dir = p7_prepare_case("for_arm_of_value_if", "for_arm")
    p7_write(dir, "src/main.w", "enum PlVal:\n    Str(s: str)\nfn flat(v: PlVal) -> List[PlVal]:\n    match move v:\n        other => [other]\ntype P { n: i32, pos: i32 }\nimpl P:\n    mut fn items() -> Result[List[PlVal], str]:\n        var out: List[PlVal] = []\n        while self.pos < self.n:\n            let row = self.pos % 2 == 0\n            let v = PlVal.Str(f\"x{self.pos}\")\n            if row: out.push(v) else: for item in flat(v).into_iter(): out.push(item)\n            self.pos += 1\n        Ok(out)\nfn main:\n    var p = P { n: 3, pos: 0 }\n    match p.items():\n        Ok(xs) => print(xs.len())\n        Err(e) => print(e)\n")
    let result = p7_run(dir, "for_arm_resolution", "analyze\0src/main.w\0audit:resolution\0")
    p7_assert_success(result, "for_arm")
    assert(result.stdout.contains("violations=0"))
    print("ok")
