//! expect-exit: 134
//! expect-stderr: loading config: Missing(["a.toml", "b.toml"])

// D61: an expect on Err panics with its message and the error's `:?` form.

enum ConfigError:
    Missing(Vec[str])
    Unreadable

fn load() -> Result[i32, ConfigError]:
    let tried: Vec[str] = Vec.new()
    tried.push("a.toml")
    tried.push("b.toml")
    Err(.Missing(tried))

fn main:
    let _ = load().expect("loading config")
