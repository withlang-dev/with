//! expect-stdout: board=7 list=2

// A `mut self` receiver is the place the method mutates: an element
// (`self.cells[i].bump()`, D27) is never copied out of its view first. MIR
// lowered the receiver through a shared view and mutated through it; the
// LLVM backend's opaque pointers hid it, and the emitted C passed a `const`
// view to the mutating call.

type Counter { n: i32 }

impl Counter:
    mut fn bump(): self.n += 1

type Board { cells: List[Counter] }

impl Board:
    mut fn bump_at(i: i32): self.cells[i].bump()

fn main:
    var board = Board { cells: [Counter { n: 0 }, Counter { n: 5 }] }
    board.bump_at(1)
    board.bump_at(1)
    var counters = [Counter { n: 1 }]
    counters[0].bump()
    print(f"board={board.cells[1].n} list={counters[0].n}")
