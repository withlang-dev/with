//! expect-stdout: ok

var TRACE: str = ""

type Guard {
    id: str,
}

impl Drop for Guard:
    fn drop(self: Self):
        TRACE = TRACE ++ self.id

fn test_forward_goto:
    var x = 0
    goto 'set
    x = 99
    'set:
        x = 1
    assert(x == 1)

fn test_backward_goto_loop:
    var i = 0
    var sum = 0
    'again:
        if i == 4:
            goto 'done
        sum += i
        i += 1
        goto 'again
    'done:
        assert(sum == 6)

fn test_adjacent_labels:
    var x = 0
    goto 'second
    'first
    'second:
        x = 7
    assert(x == 7)

fn test_cleanup_on_goto:
    TRACE = ""
    'outer:
        defer TRACE = TRACE ++ "A"
        'inner:
            defer TRACE = TRACE ++ "B"
            goto 'done
    'done:
        assert(TRACE == "BA")

fn test_drop_on_goto:
    TRACE = ""
    'outer:
        let a = Guard { id: "A" }
        'inner:
            let b = Guard { id: "B" }
            goto 'done
    'done:
        assert(TRACE == "BA")

fn main:
    test_forward_goto()
    test_backward_goto_loop()
    test_adjacent_labels()
    test_cleanup_on_goto()
    test_drop_on_goto()
    print("ok")
