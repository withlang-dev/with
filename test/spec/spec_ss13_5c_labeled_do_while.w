//! expect-stdout: ok

fn test_labeled_colon_break:
    var i = 0
    'lp do:
        i += 1
        if i == 3:
            break 'lp
    while i < 10
    assert(i == 3)

fn test_labeled_continue_checks_condition:
    var body_count = 0
    var condition_count = 0
    var i = 0
    'lp do:
        body_count += 1
        continue 'lp
    while { condition_count += 1; i += 1; i < 3 }
    assert(body_count == 3)
    assert(condition_count == 3)

fn test_nested_labeled_do_break_outer:
    var outer_count = 0
    var inner_count = 0
    'outer do:
        outer_count += 1
        'inner do:
            inner_count += 1
            if inner_count == 1:
                continue 'inner
            break 'outer
        while inner_count < 10
    while outer_count < 10
    assert(outer_count == 1)
    assert(inner_count == 2)

fn test_label_on_own_line:
    var i = 0
    'own
    do:
        i += 1
        if i == 2:
            break 'own
    while true
    assert(i == 2)

fn test_labeled_brace_form:
    var i = 0
    'br do {
        i += 1
        if i == 2:
            break 'br
    } while true
    assert(i == 2)

fn main:
    test_labeled_colon_break()
    test_labeled_continue_checks_condition()
    test_nested_labeled_do_break_outer()
    test_label_on_own_line()
    test_labeled_brace_form()
    print("ok")
