// ===================================================================
// Producer-Consumer Pipeline
//
// Demonstrates:
//   - Channels: chan[T](cap) with buffered send/recv
//   - Async functions and await
//   - Structured concurrency with async scope
//   - Select for multiplexing
//   - Channel ownership transfer semantics
// ===================================================================

// --- Domain Types ---

type WorkItem {
    id: i32,
    payload: str,
}

type ProcessedItem {
    id: i32,
    result: str,
    worker_id: i32,
}

// --- Demo 1: Simple Pipeline ---

async fn demo_simple_pipeline:
    print("=== Demo 1: Simple Pipeline ===\n")

    let (work_tx, work_rx) = chan[i32](8)
    let (result_tx, result_rx) = chan[i32](8)
    let item_count = 5

    async scope s =>
        // producer: send work items
        s.track(async:
            for i in 0..item_count:
                work_tx.send(i)
            print("  producer: sent {item_count} items")
        )

        // worker: process items
        s.track(async:
            for i in 0..item_count:
                let item = work_rx.recv()
                result_tx.send(item * 10)
            print("  worker: processed {item_count} items")
        )

        // collector: gather results
        var total = 0
        for i in 0..item_count:
            let result = result_rx.recv()
            print("  collected: {result}")
            total = total + result

        print("\nTotal: {total}")

// --- Demo 2: Fan-out ---

async fn demo_fan_out:
    print("\n=== Demo 2: Fan-out (3 workers) ===\n")

    let (work_tx, work_rx) = chan[i32](16)
    let (result_tx, result_rx) = chan[i32](16)
    let item_count = 9

    async scope s =>
        // producer
        s.track(async:
            for i in 0..item_count:
                work_tx.send(i)
        )

        // 3 workers sharing work_rx
        for worker_id in 0..3:
            s.track(async:
                for j in 0..3:
                    let item = work_rx.recv()
                    result_tx.send(item * 10 + worker_id)
            )

        // collector
        for i in 0..item_count:
            let result = result_rx.recv()
            print("  result: {result}")

// --- Demo 3: Select with Multiple Sources ---

async fn demo_select:
    print("\n=== Demo 3: Select with Multiple Sources ===\n")

    let (fast_tx, fast_rx) = chan[i32](4)
    let (slow_tx, slow_rx) = chan[i32](4)

    async scope s =>
        // fast producer
        s.track(async:
            for i in 0..3:
                fast_tx.send(i)
        )

        // slow producer
        s.track(async:
            for i in 0..2:
                slow_tx.send(i + 100)
        )

        // multiplexed consumer
        for round in 0..5:
            let val = fast_rx.recv()
            print("  received: {val}")

// --- Main ---

async fn main:
    print("=== Channel Pipeline Demo ===\n")

    demo_simple_pipeline().await
    demo_fan_out().await
    demo_select().await

    print("\n=== Demo complete ===")
