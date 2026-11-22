// Spec test: Section 4.3 — Record Update Drops Overwritten Fields.

var RECORD_UPDATE_DROP_TRACE = ""

type RecordUpdateDropField { id: str }

impl Drop for RecordUpdateDropField:
    fn drop(move self: Self):
        RECORD_UPDATE_DROP_TRACE = RECORD_UPDATE_DROP_TRACE ++ self.id

type RecordUpdateDropPoint {
    x: RecordUpdateDropField,
    y: RecordUpdateDropField,
}

fn record_update_make_point -> RecordUpdateDropPoint:
    RecordUpdateDropPoint {
        x: RecordUpdateDropField { id: "old-x" },
        y: RecordUpdateDropField { id: "y" },
    }

fn test_record_update_drops_overwritten_field_and_moves_rest:
    RECORD_UPDATE_DROP_TRACE = ""
    let p1 = record_update_make_point()
    let p2 = { p1 with x: RecordUpdateDropField { id: "new-x" } }
    assert(p2.x.id == "new-x")
    assert(p2.y.id == "y")
    assert(RECORD_UPDATE_DROP_TRACE == "old-x")
