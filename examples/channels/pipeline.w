module channels

// ===================================================================
// Producer-Consumer Pipeline
//
// Demonstrates:
//   - Channels: chan[T] with buffered send/recv
//   - Async functions and await
//   - Structured concurrency with async scope
//   - Select for multiplexing with timeout
//   - Pipeline operator composition
//   - Fan-out / fan-in patterns
//   - Channel ownership transfer semantics
// ===================================================================

// --- Domain Types ---

type WorkItem = {
    id: u64,
    payload: str,
}

type ProcessedItem = {
    id: u64,
    result: str,
    worker_id: u32,
}

type Stats = {
    total: u64 = 0,
    successes: u64 = 0,
    failures: u64 = 0,
}

// --- Stage 1: Producer ---
//
// Generates work items and sends them into a channel.
// Demonstrates: channel send, ownership transfer.

async fn produce(tx: Sender[WorkItem], count: u64):
    for i in 0..count:
        let item = WorkItem {
            id: i,
            payload: "task-{i}",
        }
        tx.send(item).await  // moves item into channel
    // tx is dropped here — channel closes when all senders drop

// --- Stage 2: Workers (Fan-out) ---
//
// Multiple workers read from a shared channel and process items.
// Demonstrates: async scope, spawn, shared receiver.

async fn worker(
    id: u32,
    rx: &Receiver[WorkItem],
    tx: Sender[ProcessedItem],
):
    loop:
        match rx.recv().await
            Some(item) ->
                // Simulate async processing
                sleep(Duration.from_millis(10)).await
                let result = ProcessedItem {
                    id: item.id,
                    result: item.payload |> str.to_uppercase,
                    worker_id: id,
                }
                tx.send(result).await
            None => break  // channel closed, no more items

// --- Stage 3: Collector (Fan-in) ---
//
// Collects processed results with a timeout.
// Demonstrates: select with let-else inside branches, timeout.

async fn collect_results(
    rx: Receiver[ProcessedItem],
    expected: u64,
) -> Vec[ProcessedItem]:
    with Vec.new() as mut results:
        var remaining = expected
        loop:
            if remaining == 0:
                break
            select await
                opt = rx.recv() ->
                    let Some(item) = opt else
                        println("  channel closed with {remaining} items remaining")
                        break
                    println("  collected #{item.id} from worker {item.worker_id}: {item.result}")
                    results.push(item)
                    remaining = remaining - 1
                _ = timeout(Duration.from_secs(5)) ->
                    println("  timeout waiting for results!")
                    break

// --- Stage 4: Stats Aggregator ---
//
// Simple pipeline stage that computes stats from results.

fn compute_stats(results: &[ProcessedItem]):
    Stats {
        total: results.len64(),
        successes: results.iter()
            |> filter(r => not r.result.is_empty())
            |> count() as u64,
        failures: results.iter()
            |> filter(r => r.result.is_empty())
            |> count() as u64,
    }

// --- Demo 1: Simple Pipeline ---

async fn demo_simple_pipeline:
    println("=== Demo 1: Simple Pipeline ===\n")

    let (work_tx, work_rx) = chan[WorkItem](buffer: 8)
    let (result_tx, result_rx) = chan[ProcessedItem](buffer: 8)
    let item_count: u64 = 10

    async scope s =>
        // producer
        s.track(produce(work_tx, item_count))

        // single worker
        s.track(worker(0, &work_rx, result_tx))

        // collector
        let results = collect_results(result_rx, item_count).await
        let stats = compute_stats(&results)

        println("\nStats: {stats.total} total, {stats.successes} ok, {stats.failures} failed")

// --- Demo 2: Fan-out / Fan-in ---

async fn demo_fan_out:
    println("\n=== Demo 2: Fan-out / Fan-in (3 workers) ===\n")

    let (work_tx, work_rx) = chan[WorkItem](buffer: 16)
    let (result_tx, result_rx) = chan[ProcessedItem](buffer: 16)
    let item_count: u64 = 15
    let worker_count: u32 = 3

    async scope s =>
        // producer
        s.track(produce(work_tx, item_count))

        // fan-out: N workers sharing the same rx
        // Each worker gets its own clone of result_tx.
        for id in 0..worker_count:
            let tx_clone = result_tx.clone()
            s.track(worker(id, &work_rx, tx_clone))

        // Drop the original result_tx so the channel closes
        // when all worker clones are dropped.
        drop(result_tx)

        // fan-in: single collector
        let results = collect_results(result_rx, item_count).await
        let stats = compute_stats(&results)

        println("\nStats: {stats.total} total, {stats.successes} ok, {stats.failures} failed")

        // Show which worker handled what
        with Vec.new() as mut worker_counts:
            for r in results:
                // Scan for existing entry
                var found = false
                for i in 0..worker_counts.len():
                    let pair = worker_counts[i]
                    if pair.0 == r.worker_id:
                        worker_counts[i] = (r.worker_id, pair.1 + 1)
                        found = true
                        break
                if not found:
                    worker_counts.push((r.worker_id, 1 as u64))
            for pair in worker_counts:
                println("  worker {pair.0}: {pair.1} items")

// --- Demo 3: Select with Multiple Sources ---

async fn demo_select:
    println("\n=== Demo 3: Select with Multiple Sources ===\n")

    let (fast_tx, fast_rx) = chan[str](buffer: 4)
    let (slow_tx, slow_rx) = chan[str](buffer: 4)

    async scope s =>
        // fast producer — sends every 50ms
        s.track(async:
            for i in 0..5:
                sleep(Duration.from_millis(50)).await
                fast_tx.send("fast-{i}").await
        )

        // slow producer — sends every 200ms
        s.track(async:
            for i in 0..3:
                sleep(Duration.from_millis(200)).await
                slow_tx.send("slow-{i}").await
        )

        // multiplexed consumer
        var total = 0
        loop:
            if total >= 8:
                break
            select await
                opt = fast_rx.recv() ->
                    let Some(msg) = opt else break
                    println("  fast: {msg}")
                    total = total + 1
                opt = slow_rx.recv() ->
                    let Some(msg) = opt else break
                    println("  slow: {msg}")
                    total = total + 1
                _ = timeout(Duration.from_secs(1)) ->
                    println("  timeout — done waiting")
                    break

    println("\nReceived {total} messages total")

// --- Main ---

async fn main:
    println("=== Channel Pipeline Demo ===\n")

    demo_simple_pipeline().await
    demo_fan_out().await
    demo_select().await

    println("\n=== Demo complete ===")
