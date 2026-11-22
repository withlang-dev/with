//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// #2011: `select await` observes every task (the select call and a loser's
// cancel read it by copy) and, on each arm's path, takes every task once —
// the winner by its await, each loser by its cleanup await. It moved each
// task into the select, again into the winner's await and into both the
// loser's cancel and cleanup ("read of _3, which every path reaching it
// already moved out"). Each arm's temporaries drop inside the arm, and the
// winner switch has no edge to the join that skips every arm.
async fn slow() -> i32: 100

async fn fast() -> i32: 42

async fn fallible(x: i32) -> Result[i32, str]:
    if x < 0: Err("negative") else: Ok(x)

async fn race -> i32:
    let t1 = slow()
    let t2 = fast()
    select await:
        r = t2 => assert(r == 42)
        s = t1 => assert(s == 100)
    0

async fn one_arm -> Result[i32, str]:
    let task = fallible(-1)
    select await:
        value = task => value?

async fn main:
    let _ = race().await
    let _ = one_arm().await
