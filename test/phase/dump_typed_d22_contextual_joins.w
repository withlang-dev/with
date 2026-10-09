//! args: --dump-typed
//! expect-check-stdout: typed contextual-joins=
//! expect-check-stdout: bind borrowed: &i32
//! expect-check-stdout: bind anchored: i32
//! expect-check-stdout: bind anchored_reversed: i32
//! expect-check-stdout: bind pinned: i32
//! expect-check-stdout: bind owned_last: i32
//! expect-check-stdout: bind owned_first: i32
//! expect-check-stdout: bind five_views: &i32
//! expect-check-stdout: bind sequence: List[i32]
//! expect-check-stdout: bind pinned_sequence: List[i32]
//! expect-check-stdout: bind some_first: Option[i32]
//! expect-check-stdout: bind none_first: Option[i32]
//! expect-check-stdout: bind chained_some_first: Option[i32]
//! expect-check-stdout: bind chained_none_first: Option[i32]
//! expect-check-stdout: bind matched_some_first: Option[i32]
//! expect-check-stdout: bind matched_none_first: Option[i32]
//! expect-check-stdout: bind sequence_some_first: List[Option[i32]]
//! expect-check-stdout: bind sequence_none_first: List[Option[i32]]
//! expect-check-stdout: final=&i32 expected=<inferred> expected-anchor=0 arms=2 owned-anchors=0 materialized=0 views=2 diverging=0
//! expect-check-stdout: final=i32 expected=<inferred> expected-anchor=0 arms=2 owned-anchors=1 materialized=1 views=0 diverging=0
//! expect-check-stdout: final=i32 expected=i32 expected-anchor=1 arms=2 owned-anchors=0 materialized=2 views=0 diverging=0
//! expect-check-stdout: final=i32 expected=<inferred> expected-anchor=0 arms=5 owned-anchors=1 materialized=4 views=0 diverging=0
//! expect-check-stdout: final=&i32 expected=<inferred> expected-anchor=0 arms=5 owned-anchors=0 materialized=0 views=5 diverging=0

// Stage 3 is check-only. Both arm orders must yield the same decision, patterns
// preserve exact references, and an enclosing expected type is the only
// expectation allowed to reach individual arms before the join is resolved.
fn main:
    let left = 121
    let right = 122
    let left_view = &left
    let right_view = &right

    let borrowed = if true: left_view else: right_view
    let anchored = if true: left_view else: 123
    let anchored_reversed = if false: 123 else: left_view
    let pinned: i32 = if true: left_view else: right_view

    let pick = 2
    let owned_last = match pick:
        0 => left_view
        1 => right_view
        2 => left_view
        3 => right_view
        _ => 124
    let owned_first = match pick:
        0 => 124
        1 => right_view
        2 => left_view
        3 => right_view
        _ => left_view
    let five_views = match pick:
        0 => left_view
        1 => right_view
        2 => left_view
        3 => right_view
        _ => left_view

    let sequence = [left_view, 125]
    let pinned_sequence: List[i32] = [left_view, right_view]

    // Context-dependent variant shorthand is completed only after an
    // independent arm establishes the enum instantiation. Arm order is not
    // semantic.
    let some_first = if true: Some(126) else: None
    let none_first = if false: None else: Some(127)
    let chained_some_first = Some(128).and_then(x => if x > 0: Some(x) else: None)
    let chained_none_first = Some(129).and_then(x => if x > 0: None else: Some(x))
    let matched_some_first = match pick:
        0 => Some(130)
        _ => None
    let matched_none_first = match pick:
        0 => None
        _ => Some(131)
    let sequence_some_first = [Some(132), None]
    let sequence_none_first = [None, Some(133)]
