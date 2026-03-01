// ===================================================================
// Pipeline Demo — Simplified
//
// Demonstrates:
//   - Pipeline operator |>
//   - Structs with defaults
//   - Methods (UFCS)
//   - String interpolation
//   - For loops and ranges
// ===================================================================

type WorkItem = {
    id: i32,
    payload: i32,
}

type ProcessedItem = {
    id: i32,
    result: i32,
    worker_id: i32,
}

type Stats = {
    total: i32,
    successes: i32,
    failures: i32,
}

// --- Processing Functions ---

fn process_item(item: WorkItem, worker_id: i32) -> ProcessedItem:
    ProcessedItem {
        id: item.id,
        result: item.payload * 2 + worker_id,
        worker_id,
    }

fn double(x: i32) -> i32: x * 2

fn add_ten(x: i32) -> i32: x + 10

// --- Pipeline Stage Functions ---

fn produce_items(count: i32) -> i32:
    var total = 0
    for i in 0..count:
        let item = WorkItem { id: i, payload: i * 10 }
        let processed = process_item(item, 0)
        total = total + processed.result
    total

// --- Stats computation ---

fn count_positive(a: i32, b: i32, c: i32, d: i32, e: i32) -> i32:
    var n = 0
    if a > 0:
        n = n + 1
    if b > 0:
        n = n + 1
    if c > 0:
        n = n + 1
    if d > 0:
        n = n + 1
    if e > 0:
        n = n + 1
    n

// --- Main ---

fn main:
    println("=== Pipeline Demo ===")

    // Demo 1: Pipeline operator composition
    let result = 5 |> double |> add_ten |> double
    println("Pipeline: 5 |> double |> add_ten |> double = {result}")

    // Demo 2: Produce and process items
    let total = produce_items(5)
    println("Processed 5 items, total = {total}")

    // Demo 3: Stats
    let successes = count_positive(10, 20, 0, 30, 0)
    let failures = 5 - successes
    println("Stats: 5 total, {successes} ok, {failures} failed")

    // Demo 4: Chained transforms
    var sum = 0
    for i in 1..5:
        sum = sum + (i |> double |> add_ten)
    println("Sum of transformed [1..5]: {sum}")

    println("=== Demo complete ===")
