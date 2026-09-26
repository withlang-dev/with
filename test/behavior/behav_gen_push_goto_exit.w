//! expect-stdout: forward 0+1+2+3 = 6
//! expect-stdout: retry 0 1 | 0 1 2 | 0 1 2 3 4 5
//! expect-stdout: nested 21
//! expect-stdout: inner 0 2 4 (6 visits)
//! expect-stdout: from generator 3 of 7

// D69 (§13.4, §13.5b, #1730): a `goto` in the body of `for x in g` to a
// label outside the loop belongs to the consumer, like a labeled `break`:
// the generator stops at its `yield` and control reaches the label — forward,
// backward (restarting the loop with a fresh generator), and out of nested
// generator loops. A label inside the body stays a jump within the body.
gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

fn forward() -> str:
    var sum = 0
    var text = "forward"
    var sep = " "
    for x in upto(100):
        sum += x
        text = text ++ f"{sep}{x}"
        sep = "+"
        if x == 3:
            goto 'done
    text = "never reached"
    'done
    return f"{text} = {sum}"

fn retry() -> str:
    var limit = 2
    var out = "retry"
    'again
    for x in upto(6):
        out = out ++ f" {x}"
        if x == limit - 1 and limit < 4:
            limit += 1
            out = out ++ " |"
            goto 'again
    return out

fn nested() -> i32:
    var found = 0
    for a in upto(5):
        for b in upto(5):
            if a * 10 + b == 21:
                found = a * 10 + b
                goto 'out
    found = -1
    'out
    return found

fn inner() -> str:
    var s = "inner"
    var visits = 0
    for x in upto(6):
        if x % 2 == 1:
            goto 'tail
        s = s ++ f" {x}"
        'tail
        visits += 1
    return f"{s} ({visits} visits)"

// A goto in a generator's own consuming loop leaves that loop; the
// generator then continues and yields on.
gen fn thirds(n: i32) -> str:
    for x in upto(n):
        if x == 3:
            goto 'emit
    'emit
    yield f"3 of {n}"

fn main:
    print(forward())
    print(retry())
    print(f"nested {nested()}")
    print(inner())
    for s in thirds(7):
        print(f"from generator {s}")
