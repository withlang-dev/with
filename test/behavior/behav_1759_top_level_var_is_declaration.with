//! expect-check-stdout: ok
// §18.5b (D74, #1759): a file is an entry source only when its top level
// holds an executable statement other than a `let`/`var`. A `var` beside
// functions is a module-level declaration every function sees — a library
// shape, no `main` — and must not become a local of a synthesized `main`
// (that read `var GLOBAL_COUNT = 0` beside a `comptime fn` as "undefined
// variable", and a migrated `var g: ctx` below the fn that reads it the
// same way).

fn bump() -> i32:
    counter = counter + 1
    counter

var counter: i32 = 3
