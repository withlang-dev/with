use std.process
use std.traits.ControlFlow
use std.sync
use std.time

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

fn loop_user_try(text: &str) -> Validation:
    for part in text.split(","):
        validate(part)?
    Valid(0)

var started: Atomic[i32]
async fn tick(): sleep(1).await
async fn cancellable(text: str) -> i32:
    for part in text.split(","):
        defer: observe_part(part)
        started.store(1, .Release)
        while part.len() > 0: tick().await
    0

fn cancel_loop():
    let parent = cancellable("bad,held".clone())
    while started.load(.Acquire) == 0: tick().await
    parent.cancel()
    parent.join_cleanup()

fn fallible(text: &str) -> Result[i32, str]:
    if text == "bad": return Err(text.clone())
    1

fn loop_return(text: &str) -> Result[i32, str]:
    for part in text.split(","):
        if part == "bad": return Err(part.clone())
    0

fn loop_try(text: &str) -> Result[i32, str]:
    for part in text.split(","):
        fallible(part)?
    0

fn nested_return(text: &str) -> Result[i32, str]:
    for part in text.split(","):
        for word in part.split("-"):
            if word == "bad": return Err(word.clone())
    0

fn use_pair(first: &str, second: i32): first.len() + second

fn argument_return(stop: bool) -> i32:
    use_pair("temporary argument".clone(), if stop: return 7 else: 3)

fn branch_return(stop: bool) -> str:
    let result = if stop: return "returned".clone() else: "continued".clone()
    result

fn choose_option(input: Option[str]) -> str:
    input ?? return "fallback".clone()

fn choose_result(input: Result[str, str]) -> str:
    input ?? return "fallback".clone()

var match_drops: Atomic[i32]
type ExitObserver { id: i32 }
impl Drop for ExitObserver:
    move fn drop():
        assert(self.id == 7)
        match_drops.fetch_add(1, .Relaxed)

fn match_subject(present: bool) -> Option[ExitObserver]:
    if present: Some(ExitObserver { id: 7 }) else: None

fn match_exit(present: bool, early: bool):
    match match_subject(present):
        Some(value) => {
            assert(value.id == 7)
            if early: return
        }
        None => return

fn iflet_exit(present: bool, early: bool):
    if let Some(value) = match_subject(present):
        assert(value.id == 7)
        if early: return
        assert(value.id == 7)

fn named_match_exit():
    let subject = match_subject(true)
    match subject:
        Some(value) => { assert(value.id == 7); return }
        None => return

fn named_iflet_exit():
    let subject = match_subject(true)
    if let Some(value) = subject:
        assert(value.id == 7)
        return

fn observe_part(part: &str):
    let first = "new".clone()
    let second = "now".clone()
    assert(part == "bad")
    assert(first == "new" and second == "now")

type Observer ephemeral { part: &str }
impl Drop for Observer:
    move fn drop(): observe_part(self.part)

fn loop_defer(text: &str):
    for part in text.split(","):
        defer: observe_part(part)
        return

fn loop_destructor(text: &str):
    for part in text.split(","):
        let observer = Observer { part }
        return

fn loop_errdefer(text: &str) -> Result[i32, str]:
    for part in text.split(","):
        errdefer: observe_part(part)
        fallible(part)?
    0

fn loop_user_errdefer(text: &str) -> Validation:
    for part in text.split(","):
        errdefer: observe_part(part)
        validate(part)?
    Valid(0)

fn loop_control(text: &str, stop: bool):
    var count = 0
    for part in text.split(","):
        if part == "bad":
            if stop: break
            else: continue
        count += 1
    count

fn main:
    let arguments = args()
    let mode = arguments[1]
    if mode == "return": assert(loop_return("bad,held").is_err())
    else if mode == "normal": assert(loop_return("good,held").is_ok())
    else if mode == "try": assert(loop_try("bad,held").is_err())
    else if mode == "try-normal": assert(loop_try("good,held").is_ok())
    else if mode == "nested": assert(nested_return("bad-word,held").is_err())
    else if mode == "argument": assert(argument_return(true) == 7)
    else if mode == "argument-normal": assert(argument_return(false) == 21)
    else if mode == "branch": assert(branch_return(true) == "returned")
    else if mode == "branch-normal": assert(branch_return(false) == "continued")
    else if mode == "break": assert(loop_control("good,bad,held", true) == 1)
    else if mode == "continue": assert(loop_control("good,bad,held", false) == 2)
    else if mode == "user-try":
        match loop_user_try("bad,held"):
            Valid(_) => assert(false)
            Invalid(message) => assert(message == "bad")
    else if mode == "user-try-normal":
        match loop_user_try("good,held"):
            Valid(value) => assert(value == 0)
            Invalid(_) => assert(false)
    else if mode == "cancel": cancel_loop()
    else if mode == "coalesce-none": assert(choose_option(None) == "fallback")
    else if mode == "coalesce-some": assert(choose_option(Some("held".clone())) == "held")
    else if mode == "coalesce-error": assert(choose_result(Err("error".clone())) == "fallback")
    else if mode == "coalesce-ok": assert(choose_result(Ok("held".clone())) == "held")
    else if mode == "match-return":
        match_exit(true, true)
        assert(match_drops.load(.Relaxed) == 1)
    else if mode == "match-normal":
        match_exit(true, false)
        assert(match_drops.load(.Relaxed) == 1)
    else if mode == "match-none":
        match_exit(false, true)
        assert(match_drops.load(.Relaxed) == 0)
    else if mode == "iflet-return":
        iflet_exit(true, true)
        assert(match_drops.load(.Relaxed) == 1)
    else if mode == "iflet-normal":
        iflet_exit(true, false)
        assert(match_drops.load(.Relaxed) == 1)
    else if mode == "iflet-none":
        iflet_exit(false, true)
        assert(match_drops.load(.Relaxed) == 0)
    else if mode == "named-match-return":
        named_match_exit()
        assert(match_drops.load(.Relaxed) == 1)
    else if mode == "named-iflet-return":
        named_iflet_exit()
        assert(match_drops.load(.Relaxed) == 1)
    else if mode == "defer": loop_defer("bad,old")
    else if mode == "destructor": loop_destructor("bad,old")
    else if mode == "errdefer": assert(loop_errdefer("bad,old").is_err())
    else if mode == "user-errdefer":
        match loop_user_errdefer("bad,old"):
            Valid(_) => assert(false)
            Invalid(message) => assert(message == "bad")
    else: assert(false)
    print("ok")
