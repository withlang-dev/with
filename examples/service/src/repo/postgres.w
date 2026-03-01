module app.repo.postgres

use app.traits.UserRepository
use app.domain.*
use app.errors.DbError
use std.time.Duration

type PgUserRepo = {
    pool: ConnectionPool,
    query_timeout: Duration = Duration.seconds(5),
}

extend PgUserRepo:
    fn new(pool: ConnectionPool):
        PgUserRepo { pool }

impl UserRepository for PgUserRepo:
    async fn find_by_id(self: &PgUserRepo, id: UserId) -> Result[Option[User], DbError]:
        let conn = self.pool.acquire().await?
        let row = conn.query_opt(
            "SELECT id, name, email, role, active FROM users WHERE id = $1",
            &[&id],
        ).await?
        row.map(|r| row_to_user(r))

    async fn find_by_email(self: &PgUserRepo, email: &str) -> Result[Option[User], DbError]:
        let conn = self.pool.acquire().await?
        let row = conn.query_opt(
            "SELECT id, name, email, role, active FROM users WHERE email = $1",
            &[&email],
        ).await?
        row.map(|r| row_to_user(r))

    async fn list_active(self: &PgUserRepo, limit: i32, offset: i32) -> Result[Vec[User], DbError]:
        let conn = self.pool.acquire().await?
        let rows = conn.query(
            "SELECT id, name, email, role, active FROM users WHERE active = true LIMIT $1 OFFSET $2",
            &[&limit, &offset],
        ).await?
        rows |> map(|r| row_to_user(r)) |> collect()

    async fn insert(self: &PgUserRepo, user: &User) -> Result[UserId, DbError]:
        let conn = self.pool.acquire().await?
        let row = conn.query_one(
            "INSERT INTO users (name, email, role, active) VALUES ($1, $2, $3, $4) RETURNING id",
            &[&user.name, &user.email, &role_to_str(user.role), &user.active],
        ).await?
        UserId(row.get(0))

    async fn update(self: &PgUserRepo, id: UserId, fields: &UserUpdate) -> Result[Unit, DbError]:
        let conn = self.pool.acquire().await?
        let sets = with Vec.new() as mut parts:
            if fields.name.is_some() then parts.push("name = $2")
            if fields.email.is_some() then parts.push("email = $3")
            if fields.role.is_some() then parts.push("role = $4")
            if fields.active.is_some() then parts.push("active = $5")

        if sets.is_empty() then return

        let query = "UPDATE users SET {sets.join(", ")} WHERE id = $1"
        conn.execute(&query, &[&id]).await?

    async fn delete(self: &PgUserRepo, id: UserId) -> Result[Unit, DbError]:
        let conn = self.pool.acquire().await?
        conn.execute(
            "DELETE FROM users WHERE id = $1",
            &[&id],
        ).await?

    async fn count_posts(self: &PgUserRepo, id: UserId) -> Result[i32, DbError]:
        let conn = self.pool.acquire().await?
        let row = conn.query_one(
            "SELECT COUNT(*) FROM posts WHERE author_id = $1",
            &[&id],
        ).await?
        row.get(0)

    async fn count_followers(self: &PgUserRepo, id: UserId) -> Result[i32, DbError]:
        let conn = self.pool.acquire().await?
        let row = conn.query_one(
            "SELECT COUNT(*) FROM follows WHERE followed_id = $1",
            &[&id],
        ).await?
        row.get(0)

fn row_to_user(row: &Row) -> User:
    User {
        id: UserId(row.get(0)),
        name: row.get(1),
        email: row.get(2),
        role: str_to_role(row.get(3)),
        active: row.get(4),
    }

fn role_to_str(role: Role) -> &str:
    match role
        .Admin     -> "admin"
        .Moderator -> "moderator"
        .Member    -> "member"
        .Guest     -> "guest"

fn str_to_role(s: &str) -> Role:
    match s
        "admin"     -> .Admin
        "moderator" -> .Moderator
        "member"    -> .Member
        _           -> .Guest
