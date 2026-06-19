//! expect-stdout: ok

@[derive(Clone)]
type Widget { id: i32 }

impl Widget:
    fn drop(move self: Self): ()

fn fallback_some -> Option[i32]:
    Some(9)

fn fallback_value -> i32:
    12

fn none_i32 -> Option[i32]:
    None

var OPTION_OR_ELSE_SEEN: i32 = 0

fn typed_wrong_fallback -> Option[i32]:
    OPTION_OR_ELSE_SEEN = OPTION_OR_ELSE_SEEN + 1
    Some(99)

fn main:
    let some: Option[i32] = Some(4)
    let none: Option[i32] = None

    assert(some.or_else(() => typed_wrong_fallback()).unwrap() == 4)
    assert(OPTION_OR_ELSE_SEEN == 0)
    assert(none.or_else(() => fallback_some()).unwrap() == 9)

    assert(some.unwrap_or_else(() => unreachable("Option.unwrap_or_else ran on Some")) == 4)
    assert(none.unwrap_or_else(() => fallback_value()) == 12)

    let zip_left: Option[i32] = Some(2)
    let zip_right: Option[i32] = Some(5)
    let zipped = zip_left.zip(zip_right)
    let pair = zipped.unwrap()
    assert(pair.0 == 2)
    assert(pair.1 == 5)
    let zip_left2: Option[i32] = Some(2)
    assert(zip_left2.zip(none_i32()).is_none())
    let zip_right2: Option[i32] = Some(5)
    assert(none.zip(zip_right2).is_none())

    let pair_option: Option[(i32, i32)] = Some((7, 8))
    let unzipped = pair_option.unzip()
    let unzipped_left = unzipped.0
    let unzipped_right = unzipped.1
    assert(unzipped_left.unwrap() == 7)
    assert(unzipped_right.unwrap() == 8)
    let unzip_none: Option[(i32, i32)] = None
    let split_none = unzip_none.unzip()
    let split_none_left = split_none.0
    let split_none_right = split_none.1
    assert(split_none_left.is_none())
    assert(split_none_right.is_none())

    let nested_some: Option[Option[i32]] = Some(Some(11))
    assert(nested_some.flatten().unwrap() == 11)
    let nested_none_inner: Option[Option[i32]] = Some(None)
    assert(nested_none_inner.flatten().is_none())
    let nested_none_outer: Option[Option[i32]] = None
    assert(nested_none_outer.flatten().is_none())

    let copy_source: Option[i32] = Some(21)
    let copied = copy_source.cloned()
    assert(copied.unwrap() == 21)
    let original_widget: Option[Widget] = Some(Widget { id: 33 })
    let cloned_widget = original_widget.cloned()
    assert(cloned_widget.unwrap().id == 33)

    var seen_values: Vec[i32] = Vec.new()
    let inspect_source: Option[i32] = Some(44)
    let inspected = inspect_source.inspect(_value => seen_values.push(1))
    assert(inspected.unwrap() == 44)
    assert(seen_values.len32() == 1)
    let inspected_none: Option[i32] = None
    assert(inspected_none.inspect(_value => unreachable("Option.inspect ran on None")).is_none())

    print("ok")
