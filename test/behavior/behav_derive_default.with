//! expect-stdout: ok

@[derive(Default)]
type Point { x: i32, enabled: bool }

@[derive(Default)]
type Widget { count: i32, origin: Point }

type Manual { value: i32 }

impl Default for Manual:
    fn default() -> Manual:
        Manual { value: 99 }

@[derive(Default)]
type HasManual { manual: Manual, ready: bool }

const POINT_HAS_DEFAULT: bool = comptime Point.implements(Default)
const WIDGET_HAS_DEFAULT: bool = comptime Widget.implements(Default)

fn main:
    assert(POINT_HAS_DEFAULT)
    assert(WIDGET_HAS_DEFAULT)

    let p = Point.default()
    assert(p.x == 0)
    assert(not p.enabled)

    let w = Widget.default()
    assert(w.count == 0)
    assert(w.origin.x == 0)
    assert(not w.origin.enabled)

    let h = HasManual.default()
    assert(h.manual.value == 99)
    assert(not h.ready)
    print("ok")
