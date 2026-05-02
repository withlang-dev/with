// Spec test: Section 9.1a — Default Parameter Values (formerly 25.101)
// Adapted: named arguments and implicit context not yet implemented;
// tests default parameter values which are the implemented subset.

fn label(host: str, port: i32, timeout: i32 = 30) -> str:
    f"{host}:{port}/{timeout}"

fn test_default_param:
    assert(label("db", 5432) == "db:5432/30")

fn test_all_explicit:
    assert(label("db", 5432, 5) == "db:5432/5")

// blocked: named arguments (port: 5432 syntax)
// assert(label("db", port: 5432) == "db:5432/30")
// assert(label(port: 5432, host: "db", timeout: 5) == "db:5432/5")

// blocked: implicit context (ctx: implicit &Ctx)
// type Ctx { tag: str }
// fn tag_value(value: str, ctx: implicit &Ctx, suffix: str = "!") -> str:
//     f"{ctx.tag}:{value}{suffix}"
