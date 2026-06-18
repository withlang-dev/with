//! expect-exit: 5

fn main:
    var count = 0
    'outer for i in 0..3:
        'inner while count < 10:
            count += i
            break 'inner
        if count > 3:
            break 'outer
    'done:
        count += 1
        break 'done
    'brace {
        count += 1
        break 'brace
    }
    count
