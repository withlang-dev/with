//! expect-stdout: 160000 draws, all distinct

// #985: std.random's state was a plain global that every draw read and
// wrote, so threads drawing at once read one state and drew the same value
// (a lost step). Each draw is now one compare-exchange from the state it
// read; xorshift64 repeats nothing within its period, so any duplicate
// among the threads' draws is a lost step.
use std.algorithms
use std.random
use std.sync
use std.thread

global drawn: Mutex[List[i64]] = Mutex.new(List.new())

fn draw_many(n: i32) -> i32:
    var mine: List[i64] = List.new()
    for _ in 0..n: mine.push(next())
    with drawn.enter_mut() as mut all:
        for v in mine: all.push(v)
    0

fn main:
    var hs: List[JoinHandle] = List.new()
    for _ in 0..8: hs.push(spawn_os(move () => draw_many(20000)))
    for k in 0..8: join(hs[k])
    with drawn.enter_mut() as mut all:
        all.sort()
        var dups = 0
        for i in 1..all.len():
            if all[i] == all[i - 1]: dups += 1
        if dups == 0: print(f"{all.len()} draws, all distinct") else: print(f"{dups} duplicate draws")
