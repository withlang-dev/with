//! skip
// Spec test: Section 9.1a, Section 7.3a — Named Arguments and Implicit Context (formerly 25.101)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

fn label(host: str, port: i32, timeout: i32 = 30) -> str:
    "{host}:{port}/{timeout}"

type Ctx { tag: str }
fn tag_value(value: str, ctx: implicit &Ctx, suffix: str = "!") -> str:
    "{ctx.tag}:{value}{suffix}"

fn test:
    assert(label("db", port: 5432) == "db:5432/30")
    assert(label(port: 5432, host: "db", timeout: 5) == "db:5432/5")

    with context(Ctx { tag: "gpu" }):
        assert(tag_value("sin") == "gpu:sin!")
        assert(tag_value("sin", suffix: "?") == "gpu:sin?")
