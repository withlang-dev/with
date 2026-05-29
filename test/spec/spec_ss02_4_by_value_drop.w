// Spec test: Section 2.4 — By-Value Drop (formerly 25.61)

var BY_VALUE_DROP_TRACE = ""

type ByValueDropHandle { id: str }
impl Drop for ByValueDropHandle:
    fn drop(move self: Self):
        BY_VALUE_DROP_TRACE = BY_VALUE_DROP_TRACE ++ self.id

type ByValueDropWrapper { name: str, handle: ByValueDropHandle }
impl Drop for ByValueDropWrapper:
    fn drop(move self: Self):
        BY_VALUE_DROP_TRACE = BY_VALUE_DROP_TRACE ++ self.name

fn by_value_drop_make_wrapper:
    let _w = ByValueDropWrapper {
        name: "W",
        handle: ByValueDropHandle { id: "H" },
    }

// PASS: drop takes self by value, and field destructors run after user drop.
fn test_by_value_drop_body_then_fields:
    BY_VALUE_DROP_TRACE = ""
    by_value_drop_make_wrapper()
    assert(BY_VALUE_DROP_TRACE == "WH")
