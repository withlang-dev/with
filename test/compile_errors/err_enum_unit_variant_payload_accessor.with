//! expect-check-fail: unit enum variant has no payload accessor

enum UnitAccessorColor { Red | Green }

fn bad_unit_payload_accessor:
    let color = UnitAccessorColor.Red
    let _payload = color.as_red()
