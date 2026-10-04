//! expect-debug-alloc: leak count=0
//! expect-stdout: resumed=0 batch_drops=0 live=0
// #1985 (§14.3 INVARIANT 5, §14.7): `may_suspend` is part of callable type
// information for closures, function values and `dyn` callables, so a call
// through one whose target is a sync fn that may suspend unwinds its async
// caller on cancellation exactly like the direct call (#916). Before the
// fix the caller resumed past the indirect call and dropped the callee's
// never-written `Batch`. Covered: a closure binding, a fn value binding, a
// fn-typed parameter, a fn value in a struct field, and a `dyn` method.
use std.task.Task
use std.box.Box
use std.collections.Atomic
extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step()

var resumed: Atomic[i32]
var batch_drops: Atomic[i32]

type Batch { values: Vec[i32] }
impl Drop for Batch:
    move fn drop():
        batch_drops.fetch_add(1, .SeqCst)

async fn tick() -> i32: 1

async fn wait_forever(value: i32) -> i32:
    while true:
        let _ = tick().await
    value

// A sync fn that suspends: it awaits each task.
fn eat(tasks: Vec[Task[i32]]) -> Batch:
    let pending = tasks
    defer:
        while pending.len() > 0: pending.remove(0).join_cleanup()
    let values: Vec[i32] = Vec.new()
    while pending.len() > 0:
        values.push(pending.remove(0).await)
    Batch { values }

fn two_tasks -> Vec[Task[i32]]:
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(wait_forever(1))
    tasks.push(wait_forever(2))
    tasks

fn apply(f: fn(Vec[Task[i32]]) -> Batch, tasks: Vec[Task[i32]]) -> Batch: f(tasks)

type Holder { f: fn(Vec[Task[i32]]) -> Batch }

trait Eater:
    fn eat_tasks(self: &Self, tasks: Vec[Task[i32]]) -> Batch

type Glutton { n: i32 }
impl Eater for Glutton:
    fn eat_tasks(self: &Self, tasks: Vec[Task[i32]]) -> Batch: eat(tasks)

async fn closure_parent -> i32:
    let c = (tasks: Vec[Task[i32]]) => eat(tasks)
    let batch = c(two_tasks())
    resumed.fetch_add(1, .SeqCst)
    batch.values.len() as i32

async fn fn_value_parent -> i32:
    let g = eat
    let batch = g(two_tasks())
    resumed.fetch_add(1, .SeqCst)
    batch.values.len() as i32

async fn param_parent -> i32:
    let batch = apply(eat, two_tasks())
    resumed.fetch_add(1, .SeqCst)
    batch.values.len() as i32

async fn field_parent -> i32:
    let h = Holder { f: eat }
    let batch = (h.f)(two_tasks())
    resumed.fetch_add(1, .SeqCst)
    batch.values.len() as i32

async fn dyn_parent -> i32:
    let e: Box[dyn Eater] = Box.new(Glutton { n: 1 })
    let batch = e.eat_tasks(two_tasks())
    resumed.fetch_add(1, .SeqCst)
    batch.values.len() as i32

fn cancel_while_suspended(p: Task[i32]) -> i32:
    let baseline = with_fiber_live_fibers()
    var steps = 0
    while with_fiber_live_fibers() < baseline + 3 and steps < 128:
        with_runtime_run_one_step()
        steps = steps + 1
    p.cancel()
    p.join_cleanup()
    with_fiber_live_fibers()

fn main:
    let baseline = with_fiber_live_fibers()
    var live = cancel_while_suspended(closure_parent()) - baseline
    live = live + cancel_while_suspended(fn_value_parent()) - baseline
    live = live + cancel_while_suspended(param_parent()) - baseline
    live = live + cancel_while_suspended(field_parent()) - baseline
    live = live + cancel_while_suspended(dyn_parent()) - baseline
    print(f"resumed={resumed.load(.SeqCst)} batch_drops={batch_drops.load(.SeqCst)} live={live}")
    assert(resumed.load(.SeqCst) == 0 and batch_drops.load(.SeqCst) == 0 and live == 0)
