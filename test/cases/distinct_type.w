// Test: distinct types (nominal wrappers)
type UserId = distinct i32
type GroupId = distinct i32

fn get_user_id() -> UserId =
    UserId { value: 42 }

fn get_group_id() -> GroupId =
    GroupId { value: 99 }

fn main() -> i32 =
    let uid = get_user_id()
    let gid = get_group_id()

    assert(uid.value == 42)
    assert(gid.value == 99)

    // Distinct types have field access via .value
    let sum = uid.value + gid.value
    assert(sum == 141)

    println("all distinct type tests passed")
    0
