//! expect-check-fail: 'Slot.zeroed()' is not available: field 'state.kind' (Kind) has no all-zero value

// §16.2b.3: a With enum is zero-valid only when 0 is one of its
// discriminants; reading a zeroed `Kind` would match no variant. The
// refusal names the field's path through the nested record.
enum Kind: i32:
    Red = 1
    Blue = 2

@[repr(C)]
type State { kind: Kind, n: i32 }

@[repr(C)]
type Slot { id: i32, state: State }

fn main:
    let s = Slot.zeroed()
    print(s.id)
