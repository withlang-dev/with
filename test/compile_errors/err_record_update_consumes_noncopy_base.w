//! expect-check-fail: use of moved value

type RecordUpdateMovePoint { x: str, y: str }

fn bad_record_update_use_after_move:
    let p1 = RecordUpdateMovePoint { x: "first", y: "second" }
    let _p2 = { p1 with x: "third" }
    let _bad = p1.y

