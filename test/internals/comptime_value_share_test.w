//! expect-stdout: ok

use ComptimeValue

fn retained() -> ComptimeValue:
    let original = comptime_value_str("retained immutable text")
    comptime_value_share(&original)

fn drop_snapshot_first(value: &ComptimeValue):
    let snapshot = comptime_value_share(value)
    assert(snapshot.text_refs == value.text_refs)
    assert(unsafe { *value.text_refs } == 2)
    // Ordinary owned text materialization still requires a deep clone.
    let materialized = comptime_value_clone(&snapshot)
    assert(materialized.text == value.text)
    assert(materialized.text_refs != value.text_refs)
    assert(unsafe { *materialized.text_refs } == 1)

fn main:
    // The original dies before its retained snapshot.
    let value = retained()
    assert(value.text == "retained immutable text")
    assert(unsafe { *value.text_refs } == 1)
    drop_snapshot_first(&value)
    // The snapshot dies before the original; the remaining owner is valid.
    assert(unsafe { *value.text_refs } == 1)
    assert(value.text == "retained immutable text")
    print("ok")
