module domain

type UserId { value: i64 }

type User {
    id: UserId,
    name: str,
    email: str,
    role: Role,
    active: bool = true,
}

enum Role { | Admin | Moderator | Member | Guest }

type UserProfile {
    user: User,
    post_count: i32,
    followers: i32,
    last_login: Option[i64] = None,
}

type CreateUserRequest {
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

type Notification {
    recipient: str,
    subject: str,
    body: str,
    priority: Priority,
}

enum Priority { | Urgent | Normal | Low }
