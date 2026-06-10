fn private_fn -> i32:
    1

type PrivateType {
    value: i32,
}

const PRIVATE_CONST = 2

global PRIVATE_GLOBAL = 3

pub type PublicType {
    value: i32,
}

pub const PUBLIC_CONST: i32 = 7

pub global PUBLIC_GLOBAL: i32 = 11

pub fn make_public(value: i32) -> PublicType:
    PublicType { value }

pub fn public_value(value: PublicType) -> i32:
    value.value

pub fn same_module_private_sum -> i32:
    let private_value = PrivateType { value: private_fn() }
    private_value.value + PRIVATE_CONST + PRIVATE_GLOBAL

