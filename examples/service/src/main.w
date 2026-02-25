module app.main

use app.service.{UserService, ServiceConfig}
use app.errors.{ServiceError, ContextError}
use std.io.IoError
use app.repo.postgres.PgUserRepo
use app.cache.redis.RedisCache
use app.notify.email.EmailNotifier
use app.http.{AppState, HttpResponse, handle_request}
use std.sync.Arc
use std.net.TcpStream
use std.time.Duration

// Demonstrates .context() / .with_context() (§10.6) for error wrapping.
// .context() wraps an error with a human-readable message, producing
// ContextError[E] that preserves the original error as .source.
async fn load_config_from_file(path: &str) -> Result[ServiceConfig, ContextError[IoError]] =
    let text = std.fs.read_to_string(path)
        .context("reading config from {path}")?
    toml.parse[ServiceConfig](&text)
        .with_context(|| "parsing config file {path}")?

async fn main() -> Result[Unit, ServiceError] =
    // Configuration — only override fields that differ from defaults
    let config = ServiceConfig {
        cache_ttl: Duration.minutes(10),
        notify_on_delete: true,
        max_batch_size: 50,
    }

    // Initialize infrastructure
    let db_pool = ConnectionPool.connect("postgres://localhost/myapp", 20).await?
    let redis = RedisClient.connect("redis://localhost:6379").await?

    // Compose the service — builder methods take self by value (§9.5)
    let service = UserService.builder()
        .repo(Box.new(PgUserRepo.new(db_pool)))
        .cache(Box.new(RedisCache.new(redis, "myapp")))
        .notifier(Box.new(EmailNotifier {
            smtp_host: "smtp.example.com",
            from_addr: "noreply@example.com",
            rate_limit: RateLimiter.new(100, Duration.minutes(1)),
        }))
        .audit(Box.new(PgAuditLog.new(db_pool.clone())))
        .config(config)
        .build()?

    let state = Arc.new(AppState { service: Arc.new(service) })

    let listener = std.net.TcpListener.bind("0.0.0.0:8080").await?
    println("Listening on :8080")

    // Structured concurrency: all connection fibers are children of this scope.
    // On shutdown, the scope cancels all children and waits for cleanup.
    async scope |s|:
        let shutdown = s.track(listen_for_shutdown())

        loop:
            // Race: accept a new connection OR receive shutdown signal
            select await
                result = listener.accept() ->
                    match result
                        Ok(conn) ->
                            s.track(handle_connection(state.clone(), conn))
                        Err(e) ->
                            eprintln("Accept error: {e}")
                _ = shutdown ->
                    println("Shutdown signal received, draining connections...")
                    break

    // Scope guarantees: all spawned fibers have completed or been cancelled.
    println("Service shut down cleanly.")


async fn listen_for_shutdown() =
    std.signal.wait(Signal.SIGTERM).await


// ---------------------------------------------------------------------------
// Connection handling — timeout wrapping + error recovery
// ---------------------------------------------------------------------------

async fn handle_connection(state: Arc[AppState], conn: TcpStream) =
    let req = http.parse_request(&conn).await

    let result = with_timeout(
        Duration.seconds(5),
        handle_request(&state, req),
    ).await

    let resp = match result
        Ok(r)              -> r
        Err(.Timeout(..))  -> HttpResponse.json(408, "\"request timeout\"")
        Err(e)             -> HttpResponse.internal_error(&e.to_string())

    conn.write_all(resp.as_bytes()).await


// ---------------------------------------------------------------------------
// Timeout utility — select + task cancellation
// ---------------------------------------------------------------------------

// Runs `task` with a deadline. If the timer fires first, the task is
// cancelled. Cancellation triggers unwinding — all destructors run,
// all `with`-block guards are released, all resources are cleaned up.
async fn with_timeout[T](
    limit: Duration,
    task: Task[T],
) -> Result[T, ServiceError] =
    let timer = async_sleep(limit)

    select await
        result = task ->
            Ok(result)
        _ = timer ->
            task.cancel()
            Err(.Timeout("request", limit))
