//! expect-stdout: ok

// Resolved implicit arguments carry a negative binding symbol, not an AST
// node. The storage audit must validate that representation on every call path.
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("named_implicit_audit", "named_implicit_audit")
    p7_write(root, "src/main.w",
        "type Context { value: i32 }\n" ++
        "type Calc { value: i32 }\n" ++
        "fn sum(value: i32 = 2, add: i32 = 0, ctx: implicit &Context) -> i32 { value * ctx.value + add }\n" ++
        "fn Calc.sum(value: i32 = 2, add: i32 = 0, ctx: implicit &Context) -> i32 { value * ctx.value + add }\n" ++
        "fn Calc.plus(self: &Self, add: i32 = 0, ctx: implicit &Context) -> i32 { self.value * ctx.value + add }\n" ++
        "fn main {\n" ++
        "    let calc = Calc { value: 2 }\n" ++
        "    with context(Context { value: 20 }) {\n" ++
        "        assert(sum(add: 2) == 42)\n" ++
        "        assert(Calc.sum(add: 2) == 42)\n" ++
        "        assert(calc.plus(add: 2) == 42)\n" ++
        "    }\n" ++
        "}\n")
    let result = p7_run(root, "named_implicit", "analyze\0src/main.w\0audit:all\0")
    p7_assert_success(result, "audit valid implicit binding markers")
    assert(result.stdout.contains("violations=0"))
    print("ok")
