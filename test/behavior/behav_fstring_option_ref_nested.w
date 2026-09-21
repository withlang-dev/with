//! expect-stdout: nested=Some(65)
//! expect-stdout: nested_debug=Some(65)
//! expect-stdout: deep=Some(65)
//! expect-stdout: nested_none=None
//! expect-stdout: text=Some(hi)
//! expect-stdout: unsigned=Some(4294967295)
//! expect-stdout: unit=Some(())
//! expect-stdout: unit_debug=Some(())
//! expect-stdout: unit_none=None
//! expect-stdout: nested_unit=Some(())
//! expect-stdout: point=Some(Point { x: 2, y: 3 })
//! expect-stdout: option=Some(Some(7))

type Point { x: i32, y: i32 }

fn main:
    // 65's first byte is 'A': interpreting a reference as a C string used
    // to print Some(A), and values without a zero byte could overread.
    let value: i32 = 65
    let view: &i32 = &value
    let nested: Option[&&i32] = Some(&view)
    print(f"nested={nested}")
    print(f"nested_debug={nested:?}")
    let outer: &&i32 = &view
    let deep: Option[&&&i32] = Some(&outer)
    print(f"deep={deep}")
    let absent: Option[&&i32] = None
    print(f"nested_none={absent}")
    let text = "hi"
    let text_view: &str = &text
    let text_option: Option[&&str] = Some(&text_view)
    print(f"text={text_option}")
    let unsigned: u32 = 4294967295
    let unsigned_view: &u32 = &unsigned
    let unsigned_option: Option[&&u32] = Some(&unsigned_view)
    print(f"unsigned={unsigned_option}")
    // Maps of references are currently rejected as ephemeral storage;
    // valid map lookups are covered by behav_fstring_option_ref.w.
    // Unit's LLVM type is void: neither Some nor None may generate a load.
    let unit: Unit = ()
    let unit_option: Option[&Unit] = Some(&unit)
    print(f"unit={unit_option}")
    print(f"unit_debug={unit_option:?}")
    let unit_none: Option[&Unit] = None
    print(f"unit_none={unit_none}")
    let unit_view: &Unit = &unit
    let nested_unit: Option[&&Unit] = Some(&unit_view)
    print(f"nested_unit={nested_unit}")
    let point = Point { x: 2, y: 3 }
    let point_option: Option[&Point] = Some(&point)
    print(f"point={point_option}")
    let inner: Option[i32] = Some(7)
    let option: Option[&Option[i32]] = Some(&inner)
    print(f"option={option}")
