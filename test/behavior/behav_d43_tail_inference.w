//! expect-stdout: ok

// D43 (#1178): an unannotated function inherits its tail's type. A branching
// tail is a value when every written arm unifies and Unit when an arm is
// missing (no else, a partial match, or an empty arm). A single-statement
// body and a block body get the same answer. #1179: a missing `if let` else
// is never a fabricated 0. #1180: `pick_block` once lowered as Unit.

var seen: i32
var calls: i32

fn bump(x: i32) -> i32:
    calls += 1
    x + 1

fn subject(p: bool) -> Option[i32]:
    if p: Some(7) else: None

enum Event { Click | Key | Scroll }

type Panel { name: str, n: i32 }

impl Panel:
    mut fn apply(e: Event):
        match e:
            Click => self.n = 1
            Key => self.name = "key"

    mut fn apply_catchall(e: Event):
        match e:
            Click => self.n = 2
            _ => {}

// Every written arm unifies: the function returns the value.
fn pick(x: bool): if x: 1 else: 2

fn pick_block(x: bool):
    seen = 0
    if x: 1 else: 2

fn pick_match(x: bool):
    match x:
        true => 1
        false => 2

fn pick_match_block(x: bool):
    seen = 0
    match x:
        true => 1
        false => 2

fn sign(a: i32):
    if a < 0: -1
    else if a == 0: 0
    else: 1

fn nested(a: bool, b: bool):
    if a:
        if b: 1 else: 2
    else: 3

fn never_arm(x: bool):
    if x: 5 else: panic("unreachable in this test")

// A missing arm: the function is Unit and the written arms are statements.
fn iflet_unit(p: bool):
    if let Some(v) = subject(p): assert(v == 7)

fn iflet_assign(p: bool):
    if let Some(v) = subject(p): seen = v

fn iflet_assign_block(p: bool):
    seen = 0
    if let Some(v) = subject(p): seen = v

fn if_assign(p: bool):
    if p: seen = 1

fn if_call(p: bool):
    if p: bump(1)

fn if_call_block(p: bool):
    seen = 0
    if p: bump(1)

fn chain_missing(a: i32):
    if a < 0: bump(1)
    else if a == 0: bump(2)

fn empty_else(p: bool):
    if p: bump(1)
    else: {}

fn partial_match(e: Event):
    match e:
        Click => bump(1)
        Key => seen = 5

fn main:
    let a: i32 = pick(true)
    let b: i32 = pick_block(true)
    let c: i32 = pick_match(false)
    let d: i32 = pick_match_block(false)
    assert(a == 1 and b == 1 and c == 2 and d == 2)
    assert(pick_block(false) == 2)
    assert(sign(-4) == -1 and sign(0) == 0 and sign(9) == 1)
    assert(nested(true, false) == 2 and nested(false, true) == 3)
    assert(never_arm(true) == 5)

    iflet_unit(true)
    iflet_unit(false)
    iflet_assign(true)
    assert(seen == 7)
    seen = 3
    iflet_assign(false)
    assert(seen == 3)
    iflet_assign_block(true)
    assert(seen == 7)
    if_assign(true)
    assert(seen == 1)

    calls = 0
    if_call(true)
    if_call(false)
    if_call_block(true)
    chain_missing(-1)
    chain_missing(0)
    chain_missing(1)
    empty_else(true)
    empty_else(false)
    partial_match(Event.Click)
    partial_match(Event.Scroll)
    assert(calls == 6)
    partial_match(Event.Key)
    assert(seen == 5)

    var panel = Panel { name: "", n: 0 }
    panel.apply(Event.Click)
    panel.apply(Event.Key)
    panel.apply(Event.Scroll)
    assert(panel.n == 1 and panel.name == "key")
    panel.apply_catchall(Event.Click)
    panel.apply_catchall(Event.Key)
    assert(panel.n == 2)
    print("ok")
