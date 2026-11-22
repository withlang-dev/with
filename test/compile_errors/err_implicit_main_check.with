//! expect-check-stdout: ok
// §18.5b (D74, #1759): a file whose top level holds executable statements is
// an entry source, and `check` applies the same rule as `run` and `build`.
// This fixture used to pin the opposite ("expected declaration").

fn shout(s: &str) -> str: s ++ "!"

print(shout("top-level"))
