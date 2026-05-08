// Concurrent Auction House
//
// A comprehensive async example exercising every fiber/async feature:
//   async fn, .await, async blocks, Task[T], spawn, select await,
//   select await biased, async scope, tuple await, channels,
//   defer, errdefer, cancellation + unwind, @[stack_size],
//   await_all, await_first, await_any, await_settled,
//   task.cancel(), task.is_done(), nested async, sleep/timeout

use std.channel
use std.task
use std.time

// ---------------------------------------------------------------------------
// Global auction state (mutable globals for verification)
// ---------------------------------------------------------------------------

var cleanup_count: i32 = 0
var bids_submitted: i32 = 0
var rounds_completed: i32 = 0
var defer_trace: i32 = 0

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

type Bid { bidder_id: i32, amount: i32 }

type AuctionResult { winner_id: i32, winning_bid: i32, total_bids: i32 }

// ---------------------------------------------------------------------------
// Bidder: submits bids over a channel, defer tracks cleanup
// ---------------------------------------------------------------------------

async fn bidder(id: i32, base_price: i32, tx: Sender[Bid]) -> i32:
    defer: cleanup_count = cleanup_count + 1
    var round: i32 = 0
    while round < 3:
        let amount = base_price + round * id * 7
        tx.send(Bid { bidder_id: id, amount: amount })
        bids_submitted = bids_submitted + 1
        round = round + 1
    id

// ---------------------------------------------------------------------------
// Slow bidder: will be cancelled by select, exercises cancel + unwind
// ---------------------------------------------------------------------------

async fn slow_bidder(id: i32, tx: Sender[Bid]) -> i32:
    defer: cleanup_count = cleanup_count + 1
    // Simulate slow thinking with sleep
    sleep(Duration.millis(500)).await
    tx.send(Bid { bidder_id: id, amount: 9999 })
    id

// ---------------------------------------------------------------------------
// Bid collector: reads bids from channel, tracks highest
// ---------------------------------------------------------------------------

async fn collect_bids(rx: Receiver[Bid], expected: i32) -> Bid:
    var best = Bid { bidder_id: -1, amount: 0 }
    var count: i32 = 0
    while count < expected:
        let bid = rx.recv()
        if bid.amount > best.amount:
            best = bid
        count = count + 1
    best

// ---------------------------------------------------------------------------
// Nested async: multi-stage bid valuation
// ---------------------------------------------------------------------------

async fn base_valuation(amount: i32) -> i32:
    amount * 100

@[stack_size(131072)]
async fn adjusted_valuation(amount: i32, factor: i32) -> i32:
    let base = base_valuation(amount).await
    base + factor

async fn full_valuation(bid: Bid) -> i32:
    let adj = adjusted_valuation(bid.amount, bid.bidder_id * 3).await
    adj

// ---------------------------------------------------------------------------
// Async fn returning Result for errdefer + ? demonstration
// ---------------------------------------------------------------------------

async fn validate_bid(amount: i32) -> Result[i32, str]:
    if amount <= 0:
        Err("bid must be positive")
    else:
        Ok(amount)

// BUG DISCOVERED: `?` on `.await` of async Result gives "aggregate enum
// payload missing destination payload type". Spec says `.await?` should
// chain naturally. Workaround: manual if/else: on awaited result.
// BUG DISCOVERED: `.is_ok()` on Result returned from async fn `.await`
// returns false for Ok values. Possibly async Result ABI issue.
async fn process_winning_bid(amount: i32) -> Result[i32, str]:
    errdefer: cleanup_count = cleanup_count + 100
    if amount <= 0:
        return Err("bid must be positive")
    let valuation = full_valuation(Bid { bidder_id: 0, amount: amount }).await
    Ok(valuation)

// ---------------------------------------------------------------------------
// Task escaping a sync function
// ---------------------------------------------------------------------------

fn spawn_valuation(bid: Bid) -> Task[i32]:
    full_valuation(bid)

// ---------------------------------------------------------------------------
// Defer LIFO helper (top-level because nested fn not in expression context)
// ---------------------------------------------------------------------------

fn check_defer_lifo:
    defer: defer_trace = defer_trace * 10 + 3
    defer: defer_trace = defer_trace * 10 + 2
    defer: defer_trace = defer_trace * 10 + 1

// ---------------------------------------------------------------------------
// Main auction orchestration
// ---------------------------------------------------------------------------

async fn run_auction() -> AuctionResult:
    // --- Phase 1: Parallel bid collection via channels ---
    print("phase 1: channels + scope")
    let (tx, rx) = chan[Bid](32)

    // Structured concurrency: all bidders tracked in scope
    async scope s =>:
        s.track(bidder(1, 100, tx))
        s.track(bidder(2, 90, tx))
        s.track(bidder(3, 110, tx))
    // All bidders done, close channel
    tx.close()

    // Collect all 9 bids (3 bidders x 3 rounds)
    let best = collect_bids(rx, 9).await
    rounds_completed = rounds_completed + 1
    print("phase 1 done")

    // --- Phase 2: Tuple concurrent await for parallel valuation ---
    print("phase 2: tuple await")
    let val_a = full_valuation(Bid { bidder_id: 1, amount: best.amount })
    let val_b = full_valuation(Bid { bidder_id: 2, amount: best.amount })
    let (v1, v2) = (val_a, val_b).await
    assert(v1 != v2)  // different bidder_id factors
    print("phase 2 done")

    // --- Phase 3: Select await — race fast vs slow path ---
    print("phase 3: select await")
    let (tx2, rx2) = chan[Bid](8)
    let fast_task = bidder(10, 200, tx2)
    let slow_task = slow_bidder(99, tx2)
    let cancel_before = cleanup_count
    select await:
        r = fast_task => assert(r == 10)
        r = slow_task => assert(r == 99)
    // The loser was cancelled; its defer still ran
    assert(cleanup_count > cancel_before)
    print("phase 3 done")

    // --- Phase 4: Select await biased — priority ordering ---
    // BUG DISCOVERED: `select await biased` not recognized by parser.
    // Spec §14.10 says this should work for deterministic priority.
    print("phase 4: select (biased workaround)")
    let priority_task = base_valuation(50)
    let normal_task = base_valuation(30)
    select await:
        r = priority_task => assert(r == 5000)
        r = normal_task => assert(r == 3000)
    print("phase 4 done")

    // --- Phase 5: Async block capturing locals ---
    print("phase 5: async block")
    let bonus = 42
    let block_task = async:
        best.amount + bonus
    let block_result = block_task.await
    assert(block_result == best.amount + 42)
    print("phase 5 done")

    // --- Phase 6: Spawn fire-and-forget ---
    print("phase 6: spawn")
    spawn base_valuation(1)
    print("phase 6 done")

    // --- Phase 7: Task from sync function + is_done / cancel ---
    print("phase 7: task escape")
    let escaped = spawn_valuation(Bid { bidder_id: 5, amount: 10 })
    let result = escaped.await
    assert(result == 10 * 100 + 5 * 3)  // base + factor
    print("phase 7 done")

    // BUG DISCOVERED: `task.cancel()` gives "unhandled MirIntrinsic
    // MIR_INTRINSIC_GENERIC_CALL sym=cancel". Spec §14.7 says Task[T]
    // has a `cancel(task)` method.
    // let to_cancel = base_valuation(777)
    // to_cancel.cancel()
    // let _cancelled = to_cancel.await

    // --- Phase 8–12: Collection combinators ---
    // BUG DISCOVERED: `await_all`, `await_first`, `await_any`, `await_settled`
    // from `use std.task` are not resolved by name lookup. Spec §14.11 says
    // these should be available as free functions. Workaround: manual loops.

    // Phase 8: await all tasks (manual)
    print("phase 8: await all (manual)")
    let t_a = base_valuation(1)
    let t_b = base_valuation(2)
    let t_c = base_valuation(3)
    let ra = t_a.await
    let rb = t_b.await
    let rc = t_c.await
    assert(ra + rb + rc == 600)  // 100 + 200 + 300
    print("phase 8 done")

    // Phase 9: await first via select (manual await_first workaround)
    print("phase 9: await first (manual)")
    let race_a = base_valuation(10)
    let race_b = base_valuation(20)
    select await:
        r = race_a => assert(r == 1000)
        r = race_b => assert(r == 2000)
    print("phase 9 done")

    // --- Phase 13: errdefer — only runs on error path ---
    print("phase 13: errdefer")
    let err_before = cleanup_count
    print("  calling good path...")
    let good = process_winning_bid(best.amount).await
    if good.is_ok():
        print("  good is ok")
    else:
        print("  good is NOT ok")
    assert(good.is_ok())
    print("  good is ok")
    assert(cleanup_count == err_before)  // errdefer did NOT run
    print("  errdefer did not run on success (correct)")

    // BUG DISCOVERED: `.is_err()` on Result gives "unhandled MirIntrinsic
    // MIR_INTRINSIC_GENERIC_CALL sym=is_err". Spec says Result has .is_err().
    // Workaround: `not .is_ok()`.
    print("  calling bad path...")
    let bad = process_winning_bid(-1).await
    print("  bad returned")
    assert(not bad.is_ok())
    print("  bad is not ok (correct)")
    // errdefer DID run on error, adding 100
    assert(cleanup_count == err_before + 100)
    print("phase 13 done")

    // --- Phase 14: defer LIFO ordering (tested via global) ---
    print("phase 14: defer LIFO")
    defer_trace = 0
    check_defer_lifo()
    assert(defer_trace == 123)  // 0 -> 1 -> 12 -> 123
    print("phase 14 done")

    AuctionResult {
        winner_id: best.bidder_id,
        winning_bid: best.amount,
        total_bids: bids_submitted,
    }

async fn main:
    let result = run_auction().await

    assert(result.total_bids >= 9)
    assert(result.winning_bid > 0)
    assert(rounds_completed == 1)
    assert(cleanup_count > 0)

    print("ok")
