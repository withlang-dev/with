//! expect-stdout: ok

fn test_labeled_for_line_start:
    var sum = 0
    'outer for i in 0..5:
        if i == 3:
            break 'outer
        sum += i
    assert(sum == 3)

fn test_label_on_own_line:
    var count = 0
    'own
    while true:
        count += 1
        break 'own
    assert(count == 1)

fn test_label_after_left_brace:
    var count = 0
    while true { 'br do { count += 1; break 'br } while true; break }
    assert(count == 1)

fn test_label_after_semicolon:
    var count = 0
    while true { let _x = 0; 'semi while true: break 'semi; count += 1; break }
    assert(count == 1)

fn test_nested_indented_label:
    var count = 0
    if true:
        'inner while true:
            count += 1
            break 'inner
    assert(count == 1)

fn main:
    test_labeled_for_line_start()
    test_label_on_own_line()
    test_label_after_left_brace()
    test_label_after_semicolon()
    test_nested_indented_label()
    print("ok")
