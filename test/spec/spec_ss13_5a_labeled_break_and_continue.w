//! skip
// Spec test: Section 13.5a — Labeled Break and Continue (formerly 25.46a)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: labeled break exits an outer for loop
fn contains_negative(grid: [[i32]]) -> bool:
    var found = false
    'rows: for row in grid:
        for cell in row:
            if cell < 0:
                found = true
                break 'rows
    found

// PASS: labeled continue targets the outer loop
fn count_until_negative(grid: [[i32]]) -> i32:
    var count = 0
    'rows: for row in grid:
        for cell in row:
            if cell < 0:
                continue 'rows
            count += 1
    count

// PASS: brace-form labeled while
fn test:
    var i = 0
    'outer: while i < 10 {
        i += 1
        while true {
            continue 'outer
        }
    }

// PASS: labeled block supports early exit
fn parse_header(input: bytes) -> bool:
    var ok = false
    'parse:
        if input.len() < 4: break 'parse
        ok = true
    ok

// PASS: with blocks are transparent for labels
fn process(lock: &Mutex[Vec[Item]]):
    'outer: for i in 0..10:
        with lock.lock() as items:
            if items[i].is_done():
                break 'outer
            items[i].process()

// FAIL: undefined label
fn test:
    while true:
        break 'missing             // ERROR: no visible label 'missing

// FAIL: continue cannot target a labeled block
fn test:
    'block:
        continue 'block            // ERROR: cannot continue a block

// FAIL: nested labels may not shadow active labels
fn test:
    'l: for x in 0..10:
        'l: for y in 0..10:        // ERROR: label 'l shadows enclosing 'l
            break 'l

// FAIL: label must target a loop or block
fn test:
    'l: let x = 1                  // ERROR

// FAIL: labels do not cross async boundaries
fn test(flag: bool):
    'outer: while flag:
        async:
            break 'outer           // ERROR: label not visible in async block
