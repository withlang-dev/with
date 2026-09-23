//! expect-debug-alloc: leak count=0
//! expect-stdout: invalid bad
//! expect-stdout: valid 0
//! expect-stdout: found good?+
//! expect-stdout: missing bad!
//! expect-stdout: errdefer bad
//! expect-stdout: invalid bad

// A user carrier's `?` calls branch() and moves the ControlFlow payload out on
// both paths — Break into from_break (the returned carrier), Continue into the
// expression's value. branch()'s result temp kept its drop: the return
// cleanup freed the Break payload the returned carrier owned, and the
// statement end freed a non-Copy Continue payload the binding owned. The
// caller read freed memory (a Continue str read back as spaces) and freed it
// again; the str free path hid the second free until #1363's allocator fix.
// Covers: Break with a str payload, Continue with a str payload, and `?`
// under an errdefer in a loop.
use std.traits.ControlFlow

enum Validation:
    Valid(i32)
    Invalid(str)

impl Try[i32, str] for Validation:
    fn branch(move self: Self) -> ControlFlow[str, i32]:
        match self:
            Valid(value) => ControlFlow.Continue(value)
            Invalid(message) => ControlFlow.Break(message)
    fn from_break(message: str) -> Self: Invalid(message)

fn validate(text: &str) -> Validation:
    if text == "bad": return Invalid(text.clone())
    Valid(1)

fn one(text: &str) -> Validation:
    validate(text)?
    Valid(0)

enum Named:
    Found(str)
    Missing(str)

impl Try[str, str] for Named:
    fn branch(move self: Self) -> ControlFlow[str, str]:
        match self:
            Found(value) => ControlFlow.Continue(value)
            Missing(message) => ControlFlow.Break(message)
    fn from_break(message: str) -> Self: Missing(message)

fn lookup(key: &str) -> Named:
    if key == "bad": return Missing(key.clone() ++ "!")
    Found(key.clone() ++ "?")

fn decorate(key: &str) -> Named:
    let value = lookup(key)?
    Found(value ++ "+")

var errdefer_runs: i32 = 0

fn note(part: &str):
    errdefer_runs += 1
    print(f"errdefer {part}")

fn each(text: &str) -> Validation:
    for part in text.split(","):
        errdefer: note(part)
        validate(part)?
    Valid(0)

fn say(v: Validation):
    match v:
        Valid(value) => print(f"valid {value}")
        Invalid(message) => print(f"invalid {message}")

fn main:
    say(one("bad"))
    say(one("good"))
    match decorate("good"):
        Found(value) => print(f"found {value}")
        Missing(message) => print(f"missing {message}")
    match decorate("bad"):
        Found(value) => print(f"found {value}")
        Missing(message) => print(f"missing {message}")
    say(each("bad,held"))
