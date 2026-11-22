//! expect-check-fail: unknown field 'missing' for type 'DerefTarget'

type DerefTarget { name: str }
type DerefWrapper { ptr: *const DerefTarget }

impl Deref[DerefTarget] for DerefWrapper:
    fn deref(self: &Self) -> &DerefTarget:
        unsafe { self.ptr as &DerefTarget }

fn main:
    let target = DerefTarget { name: "target" }
    let wrapper = DerefWrapper { ptr: &raw const target as *const DerefTarget }
    let _missing = wrapper.missing
