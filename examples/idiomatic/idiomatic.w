// A small API service that fetches a user's dashboard data.
// This would be ~120 lines in Rust, ~90 in Go, ~80 in TypeScript.
// In With, it's ~60 lines with full error handling and concurrency.

use std.http
use std.json
use std.time

type Dashboard {
    user: User,
    posts: Vec[Post],
    notifications: Vec[Notification],
    unread: i32,
    generated_at: Timestamp,
}

enum UserStatus { Active(User) | Suspended(str) | Deleted }

async fn get_dashboard(req: &Request, db: &Pool) -> Result[Response, ApiError]:
    let user_id = req.param("id")? |> parse[UserId]?

    match db.find_user(user_id).await?:
        .Active(user) =>
            // fetch everything concurrently
            let (posts, notifs) = (
                db.recent_posts(user_id, limit: 20),
                db.notifications(user_id, unread: true),
            ).await

            let dashboard = Dashboard {
                user,
                posts: posts?,
                notifications: notifs?,
                unread: notifs?.iter() |> filter(n => n.unread) |> count,
                generated_at: Timestamp.now(),
            }

            Response.ok() |> json(dashboard)

        .Suspended(reason) =>
            Response.forbidden() |> json({ message: "Account suspended: {reason}" })

        .Deleted =>
            Response.not_found() |> json({ message: "User not found" })


// --- Middleware: retry with exponential backoff ---

async fn with_retry[T, E](attempts: i32, f: async fn -> Result[T, E]) -> Result[T, E]:
    for i in 0..attempts:
        match f().await:
            Ok(val) => return Ok(val)
            Err(e) if i == attempts - 1 => return Err(e)
            Err(_) => sleep(Duration.millis(100 * (2 ** i))).await


// --- Route setup ---

fn main:
    let db = Pool.connect(env("DATABASE_URL") ?? "postgres://localhost/app")

    let app = with Router.new() as mut r:
        r.get("/dashboard/:id", req => get_dashboard(req, &db))
        r.get("/health", _ => Response.ok() |> text("ok"))

    serve(app, port: 8080)
