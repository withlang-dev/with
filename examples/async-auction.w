// Concurrent Auction House
//
// A comprehensive async example exercising every fiber/async feature:
//   async fn, .await, async blocks, Task[T], select await,
//   select await biased, async scope, tuple await, channels,
//   defer, errdefer, cancellation + unwind, @[stack_size],
//   await_all, await_first, task.cancel(), nested async, sleep/timeout

use std.channel
use std.task
use std.time
use std.sync

// ---------------------------------------------------------------------------
// Global auction state (for verification)
//
// The program is concurrent, so shared counters are Atomic (§9.1c):
// synchronized globals are always safe.
// ---------------------------------------------------------------------------

var cleanup_count: Atomic[i32] = Atomic.new(0)
var bids_submitted: Atomic[i32] = Atomic.new(0)
var rounds_completed: Atomic[i32] = Atomic.new(0)
var defer_trace: Atomic[i32] = Atomic.new(0)

fn cleanups() -> i32: cleanup_count.load(.SeqCst)

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

type Bid { bidder_id: i32, amount: i32 }
impl Copy for Bid

type AuctionResult { winner_id: i32, winning_bid: i32, total_bids: i32 }

// ---------------------------------------------------------------------------
// Bidder: submits bids over a channel, defer tracks cleanup
//
// Every bidder owns its own Sender: a shared producer is spelled
// `tx.clone()` at the call site, and the channel closes when the last
// sender drops (§14.15).
// ---------------------------------------------------------------------------

async fn bidder(id: i32, base_price: i32, tx: Sender[Bid]) -> i32:
    defer: cleanup_count.fetch_add(1, .SeqCst)
    for round in 0..3:
        let amount = base_price + round * id * 7
        tx.send(Bid { bidder_id: id, amount })
        bids_submitted.fetch_add(1, .SeqCst)
    id

// ---------------------------------------------------------------------------
// Slow bidder: will be cancelled by select, exercises cancel + unwind
// ---------------------------------------------------------------------------

async fn slow_bidder(id: i32, tx: Sender[Bid]) -> i32:
    defer: cleanup_count.fetch_add(1, .SeqCst)
    // Simulate slow thinking with sleep
    sleep(Duration.millis(500)).await
    tx.send(Bid { bidder_id: id, amount: 9999 })
    id

// ---------------------------------------------------------------------------
// Bid collector: reads bids from channel, tracks highest
// ---------------------------------------------------------------------------

async fn collect_bids(rx: Receiver[Bid], expected: i32) -> Bid:
    var best = Bid { bidder_id: -1, amount: 0 }
    for _ in 0..expected:
        let bid = rx.recv() ?? break
        if bid.amount > best.amount:
            best = bid
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
    adjusted_valuation(bid.amount, bid.bidder_id * 3).await

// ---------------------------------------------------------------------------
// Async fn returning Result for errdefer + ? demonstration
// ---------------------------------------------------------------------------

async fn validate_bid(amount: i32) -> Result[i32, str]:
    if amount <= 0:
        return Err("bid must be positive")
    amount

async fn process_winning_bid(amount: i32) -> Result[i32, str]:
    errdefer: cleanup_count.fetch_add(100, .SeqCst)
    let valid = validate_bid(amount).await?
    full_valuation(Bid { bidder_id: 0, amount: valid }).await

// ---------------------------------------------------------------------------
// Task escaping a sync function
// ---------------------------------------------------------------------------

fn spawn_valuation(bid: Bid) -> Task[i32]:
    full_valuation(bid)

// ---------------------------------------------------------------------------
// Defer LIFO helper (top-level because nested fn not in expression context)
// ---------------------------------------------------------------------------

fn trace(digit: i32):
    defer_trace.store(defer_trace.load(.SeqCst) * 10 + digit, .SeqCst)

fn check_defer_lifo:
    defer: trace(3)
    defer: trace(2)
    defer: trace(1)

// ---------------------------------------------------------------------------
// Main auction orchestration
// ---------------------------------------------------------------------------

async fn run_auction() -> AuctionResult:
    // --- Phase 1: Parallel bid collection via channels ---
    print("phase 1: channels + scope")
    let (tx, rx) = chan[Bid](32)

    // Structured concurrency: all bidders tracked in scope, each with
    // its own clone of the sender
    async scope s =>
        s.track(bidder(1, 100, tx.clone()))
        s.track(bidder(2, 90, tx.clone()))
        s.track(bidder(3, 110, tx.clone()))
    // All bidders done and their senders dropped; close ours
    tx.close()

    // Collect all 9 bids (3 bidders x 3 rounds)
    let best = collect_bids(rx, 9).await
    rounds_completed.fetch_add(1, .SeqCst)
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
    let fast_task = bidder(10, 200, tx2.clone())
    let slow_task = slow_bidder(99, tx2)
    let cancel_before = cleanups()
    select await:
        r = fast_task => assert(r == 10)
        r = slow_task => assert(r == 99)
    // The loser was cancelled; its defer still ran
    assert(cleanups() > cancel_before)
    print("phase 3 done")

    // --- Phase 4: Select await biased — priority ordering ---
    print("phase 4: select await biased")
    let priority_task = base_valuation(50)
    let normal_task = base_valuation(30)
    select await biased:
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

    // --- Phase 6: Explicit task observation ---
    print("phase 6: task observation")
    let warmup = base_valuation(1)
    let warmup_result = warmup.await
    assert(warmup_result == 100)
    print("phase 6 done")

    // --- Phase 7: Task from sync function + cancel ---
    print("phase 7: task escape")
    let escaped = spawn_valuation(Bid { bidder_id: 5, amount: 10 })
    let result = escaped.await
    assert(result == 10 * 100 + 5 * 3)  // base + factor

    let to_cancel = base_valuation(777)
    to_cancel.cancel()
    print("phase 7 done")

    // --- Phase 8: await all tasks ---
    print("phase 8: await all")
    var valuations = Vec.new()
    valuations.push(base_valuation(1))
    valuations.push(base_valuation(2))
    valuations.push(base_valuation(3))
    let results = await_all(valuations)
    var sum = 0
    for r in results:
        sum += r
    assert(sum == 600)  // 100 + 200 + 300
    print("phase 8 done")

    // --- Phase 9: await first ---
    print("phase 9: await first")
    var racers = Vec.new()
    racers.push(base_valuation(10))
    racers.push(base_valuation(20))
    let first = await_first(racers)
    assert(first == 1000 or first == 2000)
    print("phase 9 done")

    // --- Phase 13: errdefer — only runs on error path ---
    print("phase 13: errdefer")
    let err_before = cleanups()
    let good = process_winning_bid(best.amount).await
    assert(good.is_ok())
    assert(cleanups() == err_before)  // errdefer did NOT run
    print("  errdefer did not run on success (correct)")

    let bad = process_winning_bid(-1).await
    assert(bad.is_err())
    // errdefer DID run on error, adding 100
    assert(cleanups() == err_before + 100)
    print("phase 13 done")

    // --- Phase 14: defer LIFO ordering (tested via global) ---
    print("phase 14: defer LIFO")
    defer_trace.store(0, .SeqCst)
    check_defer_lifo()
    assert(defer_trace.load(.SeqCst) == 123)  // 0 -> 1 -> 12 -> 123
    print("phase 14 done")

    AuctionResult {
        winner_id: best.bidder_id,
        winning_bid: best.amount,
        total_bids: bids_submitted.load(.SeqCst),
    }

async fn main:
    let result = run_auction().await

    assert(result.total_bids >= 9)
    assert(result.winning_bid > 0)
    assert(rounds_completed.load(.SeqCst) == 1)
    assert(cleanups() > 0)

    print("ok")
