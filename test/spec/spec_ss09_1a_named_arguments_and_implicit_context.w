//! expect-stdout: ok

// Spec test: Section 9.1a — Named Arguments, Default Parameters,
// and Implicit Parameters.

fn label(host: str, port: i32, timeout: i32 = 30) -> str:
    f"{host}:{port}/{timeout}"

type Ctx { tag: str }

fn tag_value(value: str, ctx: implicit Ctx, suffix: str = "!") -> str:
    f"{ctx.tag}:{value}{suffix}"

fn test_default_param:
    assert(label("db", 5432) == "db:5432/30")

fn test_all_explicit:
    assert(label("db", 5432, 5) == "db:5432/5")

fn test_named_arguments:
    assert(label("db", port: 5432) == "db:5432/30")
    assert(label(port: 5432, host: "db", timeout: 5) == "db:5432/5")

fn test_named_implicit_and_default_order:
    with default_ctx(Ctx { tag: "default" }):
        assert(tag_value("v") == "default:v!")
        assert(tag_value("v", suffix: "?") == "default:v?")
        assert(tag_value("v", ctx: Ctx { tag: "override" }) == "override:v!")

fn main:
    test_default_param()
    test_all_explicit()
    test_named_arguments()
    test_named_implicit_and_default_order()
    print("ok")
