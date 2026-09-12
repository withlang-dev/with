//! expect-stdout: ok

var DROPS = 0

type Parcel { text: str }

impl Drop for Parcel:
    move fn drop: DROPS = DROPS + 1

impl Parcel:
    move fn replace(other: Parcel): other

fn identity(value: Parcel): value
fn through(cb: fn(Parcel) -> Parcel, value: Parcel): cb(value)

fn main:
    let first = through(identity, Parcel { text: "first" })
    assert(first.text == "first")
    assert(DROPS == 0)
    let second = first.replace(Parcel { text: "second" })
    assert(second.text == "second")
    assert(DROPS == 1)
    second.drop()
    assert(DROPS == 2)
    let third = through(x => x, Parcel { text: "third" })
    assert(third.text == "third")
    assert(DROPS == 2)
    third.drop()
    assert(DROPS == 3)
    print("ok")
