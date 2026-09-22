//! expect-stdout: ok

// #1319 (§9.1, D43): a bare assignment as an `if`/`match` arm is that arm's
// tail and is discarded, exactly as the block spelling `{ place = value }`
// is. Mixed spellings across arms join Unit with Unit — never "i32 and
// Unit" — so the unannotated function is Unit, in either arm order.

var pass_count: i32 = 0
var fail_count: i32 = 0

fn check(ok: bool):
    if ok:
        pass_count = pass_count + 1
    else:
        print("fail")
        fail_count = fail_count + 1

fn check_reversed(ok: bool):
    if ok:
        print("pass")
        pass_count += 1
    else:
        fail_count += 1

fn check_match(ok: bool):
    match ok:
        true => pass_count = pass_count + 1
        false =>
            print("fail")
            fail_count = fail_count + 1

fn check_match_reversed(ok: bool):
    match ok:
        true =>
            print("pass")
            pass_count += 1
        false => fail_count += 1

// Both arms bare: the same answer.
fn check_bare(ok: bool): if ok: pass_count += 1 else: fail_count += 1

// #1180's shape: an assignment arm beside a Unit call arm was once a Unit
// operand stored into an i32 place; both arms are Unit now.
fn check_assert(ok: bool):
    match ok:
        true => pass_count = pass_count + 1
        false => assert(ok)

// Annotated: the arms are discarded, §4.10 returns i32.default().
fn tally(ok: bool) -> i32: if ok: pass_count += 1 else: fail_count += 1

fn main:
    check(true)
    check_reversed(false)
    check_match(true)
    check_match_reversed(false)
    check_bare(true)
    check_bare(false)
    check_assert(true)
    assert(tally(true) == 0)
    assert(pass_count == 5)
    assert(fail_count == 3)
    print("ok")
