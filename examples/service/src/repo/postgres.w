module repo.postgres

use traits.*
use domain.*
use errors.*

// --- Postgres User Repository ---
//
// Demonstrates:
//   - Trait implementation for UserRepository
//   - Pattern matching for enum conversion
//   - SQL query building with f-strings
//   - with-block for accumulating results

type PgUserRepo {
    connection_string: str,
    query_timeout_secs: i64 = 5,
}

extend PgUserRepo:
    fn new(conn: str) -> PgUserRepo:
        PgUserRepo { connection_string: conn }

impl UserRepository for PgUserRepo =
    async fn find_by_id(self: &PgUserRepo, id: UserId) -> Option[User]:
        // In production: SELECT id, name, email, role, active FROM users WHERE id = $1
        None

    async fn find_by_email(self: &PgUserRepo, email: str) -> Option[User]:
        // In production: SELECT ... FROM users WHERE email = $1
        None

    async fn list_active(self: &PgUserRepo, limit: i32, offset: i32) -> Vec[User]:
        // In production: SELECT ... FROM users WHERE active = true LIMIT $1 OFFSET $2
        Vec.new()

    async fn insert(self: &PgUserRepo, user: User) -> UserId:
        // In production: INSERT INTO users ... RETURNING id
        UserId { value: 1 }

    async fn update(self: &PgUserRepo, id: UserId, fields: UserUpdate) -> bool:
        // Build SET clause dynamically
        let sets = with Vec.new() as mut parts:
            if fields.name.is_some():
                parts.push("name = $2")
            if fields.email.is_some():
                parts.push("email = $3")
            if fields.active.is_some():
                parts.push("active = $5")

        if sets.is_empty():
            return false

        let sep = ", "
        let joined = sets.join(sep)
        let _query = "UPDATE users SET " ++ joined ++ " WHERE id = $1"
        // In production: execute the query
        true

    async fn delete(self: &PgUserRepo, id: UserId) -> bool:
        // In production: DELETE FROM users WHERE id = $1
        true

    async fn count_posts(self: &PgUserRepo, id: UserId) -> i32:
        // In production: SELECT COUNT(*) FROM posts WHERE author_id = $1
        0

    async fn count_followers(self: &PgUserRepo, id: UserId) -> i32:
        // In production: SELECT COUNT(*) FROM follows WHERE followed_id = $1
        0

// --- Helper: Convert role enum to string ---

fn role_to_str(role: Role) -> str:
    match role:
        .Admin     => "admin"
        .Moderator => "moderator"
        .Member    => "member"
        .Guest     => "guest"

// --- Helper: Convert string to role enum ---

fn str_to_role(s: str) -> Role:
    match s:
        "admin"     => .Admin
        "moderator" => .Moderator
        "member"    => .Member
        _           => .Guest
