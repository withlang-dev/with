//! skip
// Spec test: Section 10.6 — Error Context (formerly 25.43)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic .context()
fn load(path: &str) -> Result[str, ContextError[IoError]]:
    let text = fs.read_to_string(path)
        .context("failed to read config")?
    Ok(text)

fn test:
    match load("/nonexistent"):
        Err(e) =>
            assert(e.message == "failed to read config")
            assert(e.source.is_not_found())
        Ok(_) => panic("expected error")

// PASS: chained context
fn load_and_parse(path: &str) -> Result[Config, AppError]:
    let text = fs.read_to_string(path)
        .context("reading config file")?
    let config = toml.parse(text)
        .context("parsing config")?
    Ok(config)

// PASS: lazy context with .with_context()
fn find_user(id: UserId) -> Result[User, ContextError[DbError]]:
    db.query_one("SELECT * FROM users WHERE id = $1", &[&id])
        .with_context(() => "failed to find user {id}")?
