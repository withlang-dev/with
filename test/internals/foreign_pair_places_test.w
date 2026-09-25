//! expect-stdout: ok
use ForeignPairState

fn operation(action: i32, ty: i32, origin: i32) -> ForeignPairBlock:
    ForeignPairBlock { action, ty, origin, guard: -1, can_fail: false, preserves_on_failure: false, invokes: false }

fn main:
    var places = foreign_pair_places(4)
    let create = operation(FOREIGN_PAIR_CREATE, 0, -1)
    let callback = operation(FOREIGN_PAIR_CALLBACK, 17, -1)
    let userdata = operation(FOREIGN_PAIR_USERDATA, 17, 41)
    let invoke = operation(FOREIGN_PAIR_INVOKE, 0, -1)
    assert(places.apply_at(0, create))
    assert(places.apply_at(1, create))

    // r = &a; r = &b must not unify a with b. Completing b's callback
    // cannot provide a's missing userdata, even though r referred to both.
    places.borrow(2, 0)
    assert(places.apply_at(2, callback))
    places.borrow(2, 1)
    assert(places.apply_at(2, userdata))
    assert(not places.apply_at(0, invoke))
    assert(not places.apply_at(1, invoke))
    assert(places.apply_at(1, callback))
    assert(places.apply_at(1, invoke))
    assert(not places.apply_at(0, invoke))
    assert(foreign_pair_origin_live(places, 41))

    // An owned move transports state; references to the old storage do not
    // follow it. The destination retains the userdata until actual reset.
    places.move_place(3, 1)
    assert(places.apply_at(3, invoke))
    assert(not places.apply_at(2, invoke))
    assert(foreign_pair_origin_live(places, 41))
    let reset = operation(FOREIGN_PAIR_RESET, 0, -1)
    assert(places.apply_at(3, reset))
    assert(not foreign_pair_origin_live(places, 41))

    // A branch-dependent reference can change either target, not both.
    var left = foreign_pair_places(3)
    assert(left.apply_at(0, create))
    assert(left.apply_at(1, create))
    var right = foreign_pair_places_clone(left)
    left.borrow(2, 0)
    right.borrow(2, 1)
    var joined = foreign_pair_places_join(left, right)
    assert(joined.apply_at(2, callback))
    assert(not joined.apply_at(0, invoke))
    assert(not joined.apply_at(1, invoke))
    // Cloning and weak updates did not mutate either predecessor row.
    assert(left.apply_at(0, invoke))
    assert(right.apply_at(1, invoke))
    print("ok")
