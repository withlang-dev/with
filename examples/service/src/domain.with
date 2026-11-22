module domain

pub type UserId { value: i64 }

pub type User {
    id: UserId,
    name: str,
    email: str,
    role: Role,
    active: bool = true,
}

pub enum Role { | Admin | Moderator | Member | Guest }
impl Copy for Role

pub type UserProfile {
    user: User,
    post_count: i32,
    followers: i32,
    last_login: Option[i64] = None,
}

pub type CreateUserRequest {
    name: str,
    email: str,
    role: Role,
}

type UserUpdate {
    name: Option[str],
    email: Option[str],
    role: Option[Role],
    active: Option[bool],
}

pub type Notification {
    recipient: str,
    subject: str,
    body: str,
    priority: Priority,
}

enum Priority { | Urgent | Normal | Low }
impl Copy for Priority
