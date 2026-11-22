//! args: --validate-all
//! expect-check-stdout: validate-all: ok

// A `??` whose default does not return, on a Copy subject: the subject has
// nothing to drop on the default path. Dropping it anyway made it owned
// storage to the ownership validator, which then reported it Init at
// return (a leak) on the success path (found by D86, #1864).

fn main:
    let o: Option[i32] = Some(3)
    let v = o ?? panic("no value")
    print(v)
