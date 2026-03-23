//! expect-stdout: ok

// Tests: defer execution order, defer with early return, multiple defers,
//        defer with mutation, defer across function calls

var g_trace: i32 = 0

fn test_defer_runs_on_exit:
    g_trace = 0
    do_defer_work()
    assert(g_trace == 1)

fn do_defer_work:
    defer g_trace = 1
    assert(g_trace == 0)

fn test_defer_lifo_order:
    g_trace = 0
    do_lifo_defers()
    // Defers run in LIFO: last defer runs first
    // defer g_trace = g_trace * 10 + 3 (runs last)
    // defer g_trace = g_trace * 10 + 2
    // defer g_trace = g_trace * 10 + 1 (runs first)
    // 0 -> 1 -> 12 -> 123
    assert(g_trace == 123)

fn do_lifo_defers:
    defer g_trace = g_trace * 10 + 3
    defer g_trace = g_trace * 10 + 2
    defer g_trace = g_trace * 10 + 1

fn test_defer_with_early_return:
    g_trace = 0
    early_return_fn(true)
    assert(g_trace == 42)

fn early_return_fn(early: bool):
    defer g_trace = 42
    if early:
        return
    g_trace = 99

fn test_defer_mutation:
    g_trace = 0
    defer_mutates()
    // Body sets g_trace=10, then defer adds 5
    assert(g_trace == 15)

fn defer_mutates:
    defer g_trace = g_trace + 5
    g_trace = 10

fn test_multiple_defers_with_early_return:
    g_trace = 0
    multiple_defers_early(true)
    // Two defers both run even with early return, in LIFO order
    // defer g_trace = g_trace + 20 (registered second, runs first)
    // defer g_trace = g_trace + 10 (registered first, runs second)
    // 0 -> 20 -> 30
    assert(g_trace == 30)

fn multiple_defers_early(early: bool):
    defer g_trace = g_trace + 10
    defer g_trace = g_trace + 20
    if early:
        return
    g_trace = 999

fn test_defer_does_not_run_prematurely:
    g_trace = 0
    defer g_trace = 100
    // Within the same scope, defer hasn't run yet
    assert(g_trace == 0)

fn test_nested_function_defers:
    g_trace = 0
    outer_defer()
    assert(g_trace == 3)

fn inner_defer:
    defer g_trace = g_trace + 1

fn outer_defer:
    defer g_trace = g_trace + 1
    inner_defer()
    // After inner_defer returns: g_trace = 1
    // Then our defer runs: g_trace = 2
    defer g_trace = g_trace + 1

fn main:
    test_defer_runs_on_exit()
    test_defer_lifo_order()
    test_defer_with_early_return()
    test_defer_mutation()
    test_multiple_defers_with_early_return()
    test_defer_does_not_run_prematurely()
    test_nested_function_defers()
    println("ok")
