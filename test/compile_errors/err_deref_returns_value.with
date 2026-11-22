//! expect-check-fail: Deref.deref must return a reference

type DerefReturnValueUser { name: str }
type DerefReturnValueBox { value: DerefReturnValueUser }

impl Deref[DerefReturnValueUser] for DerefReturnValueBox:
    fn deref(self: &Self) -> DerefReturnValueUser:
        self.value

fn main:
    let box = DerefReturnValueBox { value: DerefReturnValueUser { name: "bad" } }
    let _name = box.name
