module app.domain

type UserId = distinct i64

@[derive(Clone)]
type User = {
    id: UserId,
    name: str,
    email: str,
    role: Role,
    active: bool = true,
}

@[derive(all)]
type Role = | Admin | Moderator | Member | Guest

type UserProfile = {
    user: User,
    post_count: i32,
    followers: i32,
    last_login: Option[Instant] = None,
}

@[derive(Clone)]
type CreateUserRequest = {
    name: str,
    email: str,
    role: Role,
}

type UserUpdate = {
    name: Option[str] = None,
    email: Option[str] = None,
    role: Option[Role] = None,
    active: Option[bool] = None,
}

type Notification = {
    recipient: str,
    subject: str,
    body: str,
    priority: Priority,
}

@[derive(all)]
type Priority = | Urgent | Normal | Low
