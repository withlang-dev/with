//! expect-error: 'resource type' declares a struct; an alias, a distinct type, an enum or a union has the identity of what it wraps (§4.3)

// D120 (§4.3): `resource` is a keyword only before `type`, and it names a
// struct; a distinct wrapper's identity is its inner type's.
resource type Token = distinct u64
fn main:
    print("unreachable")
