//! expect-stdout: ok

use ComptimeValue

// #3032 (D111/D120): a ComptimeValue's text is a str, an immutable shared
// counted buffer; a share and a clone are both one more holder of it, and
// either value may die first. The side count this file once kept
// (text_refs) counted ComptimeValues, not str copies, so a text read out
// into an owning str was freed under the copy.

fn retained() -> ComptimeValue:
    let original = comptime_value_str("retained immutable text")
    comptime_value_share(&original)

fn drop_snapshot_first(value: &ComptimeValue):
    let snapshot = comptime_value_share(value)
    assert(snapshot.text == value.text)
    let materialized = comptime_value_clone(&snapshot)
    assert(materialized.text == value.text)
    // A str read out of the value is a holder of its own (D111).
    let owned: str = snapshot.text
    assert(owned == "retained immutable text")

fn main:
    // The original dies before its retained snapshot.
    let value = retained()
    assert(value.text == "retained immutable text")
    drop_snapshot_first(&value)
    // The snapshot dies before the original; the remaining holder is valid.
    assert(value.text == "retained immutable text")
    print("ok")
