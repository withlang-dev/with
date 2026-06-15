type GenericPrivateHelper {
    value: i32,
}

pub type GenericPrivateWrapper[T] {
    value: T,
}

pub fn GenericPrivateWrapper.make[T](value: T) -> GenericPrivateWrapper[T]:
    let helper = GenericPrivateHelper { value: 7 }
    if helper.value != 7:
        panic("private helper mismatch")
    GenericPrivateWrapper { value }

pub fn GenericPrivateWrapper.private_value[T](self: &Self) -> i32:
    let helper = GenericPrivateHelper { value: 11 }
    if helper.value != 11:
        panic("private helper mismatch")
    helper.value
