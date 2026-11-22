//! expect-check-fail: use of moved value

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type RecordUpdateMovePoint { x: str, y: str }

fn bad_record_update_use_after_move:
    let p1 = RecordUpdateMovePoint { x: "first", y: "second" }
    let _p2 = { p1 with x: "third" }
    let _bad = p1.y

