//! expect-stdout: ok

// Spec test: Section 13.5a — Labeled Break and Continue (formerly 25.46a)

var TRACE: str = ""

type Guard {
    id: str,
}

impl Drop for Guard:
    fn drop(move self: Self):
        TRACE = TRACE ++ self.id

fn test_labeled_for_break:
    var count = 0
    'outer for i in 0..5:
        for j in 0..5:
            if i == 2 and j == 2:
                break 'outer
            count += 1
    assert(count == 12)

fn test_labeled_for_continue:
    var count = 0
    'outer for i in 0..3:
        for j in 0..3:
            if j == 1:
                continue 'outer
            count += 1
    assert(count == 3)

fn test_labeled_while_continue:
    var i = 0
    var hits = 0
    'outer while i < 4:
        i += 1
        while true:
            hits += 1
            continue 'outer
    assert(i == 4)
    assert(hits == 4)

fn test_labeled_blocks:
    var n = 0
    'colon:
        n = 1
        break 'colon
        n = 99
    assert(n == 1)

    'brace {
        n += 1
        break 'brace
        n = 99
    }
    assert(n == 2)

fn test_with_transparency:
    var i = 0
    'outer while i < 5:
        i += 1
        with i as value:
            if value == 3:
                break 'outer
    assert(i == 3)

fn test_cleanup_on_labeled_break:
    TRACE = ""
    'outer while true:
        defer: TRACE = TRACE ++ "A"
        'inner:
            defer: TRACE = TRACE ++ "B"
            errdefer: TRACE = TRACE ++ "E"
            break 'outer
            TRACE = TRACE ++ "x"
    assert(TRACE == "BA")

fn test_drop_on_labeled_break:
    TRACE = ""
    'outer while true:
        let a = Guard { id: "A" }
        'inner:
            let b = Guard { id: "B" }
            break 'outer
    assert(TRACE == "BA")

fn main:
    test_labeled_for_break()
    test_labeled_for_continue()
    test_labeled_while_continue()
    test_labeled_blocks()
    test_with_transparency()
    test_cleanup_on_labeled_break()
    test_drop_on_labeled_break()
    print("ok")
