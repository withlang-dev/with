# Async Service Example — Trait-Object-Heavy Architecture

This example implements a user management API backend in With. It
demonstrates how trait objects, async methods, `with` blocks, and
structured concurrency compose into a clean, production-style
service architecture.

The pattern is dependency injection via trait objects — the same
architecture you'd build in Go (interfaces), Rust (dyn Trait), or
Java (interfaces + Spring). In With, it works with zero special
machinery because `async fn` in traits just returns `Task[T]`, and
trait objects with `Task[T]` return types need no boxing.

---

## Error Types

```with
module app.errors

error DbError =
    ConnectionFailed(host: String, port: u16)
    QueryFailed(query: String, reason: String)
    NotFound(table: String, id: String)
    Timeout

error CacheError =
    ConnectionLost
    KeyTooLarge(size: usize, max: usize)
    Timeout

error NotifyError =
    ProviderDown(provider: String)
    RateLimited(retry_after: Duration)
    InvalidRecipient(addr: String)

// Unified service error — all subsystem errors convert into this
// via From impls, so ? propagation works across boundaries.
error ServiceError =
    Db(DbError)
    Cache(CacheError)
    Notify(NotifyError)
    Validation(msg: String)
    Cancelled

impl From[DbError] for ServiceError {
    fn from(e: DbError) -> ServiceError = ServiceError.Db(e)
}

impl From[CacheError] for ServiceError {
    fn from(e: CacheError) -> ServiceError = ServiceError.Cache(e)
}

impl From[NotifyError] for ServiceError {
    fn from(e: NotifyError) -> ServiceError = ServiceError.Notify(e)
}

impl From[TaskCancelled] for ServiceError {
    fn from(_: TaskCancelled) -> ServiceError = ServiceError.Cancelled
}
```

---

## Domain Types

```with
module app.domain

type UserId = distinct i64

@[derive(Clone)]
type User = {
    id: UserId,
    name: String,
    email: String,
    role: Role,
    active: bool,
}

type Role = Admin | Moderator | Member | Guest

type UserProfile = {
    user: User,
    post_count: i32,
    followers: i32,
    last_login: Option[Instant],
}

@[derive(Clone)]
type CreateUserRequest = {
    name: String,
    email: String,
    role: Role,
}

type UserUpdate = {
    name: Option[String],
    email: Option[String],
    role: Option[Role],
    active: Option[bool],
}

type Notification = {
    recipient: String,
    subject: String,
    body: String,
    priority: Priority,
}

type Priority = Urgent | Normal | Low
```

---

## Service Traits (the trait-object interfaces)

These are the seams of the architecture. Each is a trait with async
methods. Each will be used as `&dyn Trait` — meaning the caller
doesn't know (or care) whether it's talking to a real database, an
in-memory mock, or a remote microservice.

```with
module app.traits

use app.domain.*
use app.errors.*

// --- Data Access ---

trait UserRepository {
    async fn find_by_id(self: &Self, id: UserId) -> Result[Option[User], DbError]
    async fn find_by_email(self: &Self, email: &str) -> Result[Option[User], DbError]
    async fn list_active(self: &Self, limit: i32, offset: i32) -> Result[Vec[User], DbError]
    async fn insert(self: &Self, user: &User) -> Result[UserId, DbError]
    async fn update(self: &Self, id: UserId, fields: &UserUpdate) -> Result[Unit, DbError]
    async fn delete(self: &Self, id: UserId) -> Result[Unit, DbError]
    async fn count_posts(self: &Self, id: UserId) -> Result[i32, DbError]
    async fn count_followers(self: &Self, id: UserId) -> Result[i32, DbError]
}

// --- Caching ---

trait CacheService {
    async fn get[T: Deserialize](self: &Self, key: &str) -> Result[Option[T], CacheError]
    async fn set[T: Serialize](self: &Self, key: &str, val: &T, ttl: Duration) -> Result[Unit, CacheError]
    async fn delete(self: &Self, key: &str) -> Result[Unit, CacheError]
    async fn exists(self: &Self, key: &str) -> Result[bool, CacheError]
}

// --- Notifications ---

trait NotificationService {
    async fn send(self: &Self, notif: &Notification) -> Result[Unit, NotifyError]
    async fn send_batch(self: &Self, notifs: &[Notification]) -> Result[i32, NotifyError]
}

// --- Audit Logging ---

trait AuditLog {
    async fn record(self: &Self, actor: UserId, action: &str, detail: &str) -> Result[Unit, DbError]
}
```

---

## Implementations

### PostgreSQL User Repository

```with
module app.repo.postgres

use app.traits.UserRepository
use app.domain.*
use app.errors.DbError
use std.time.Duration

type PgUserRepo = {
    pool: ConnectionPool,
    query_timeout: Duration,
}

extend PgUserRepo
    fn new(pool: ConnectionPool, timeout: Duration) -> PgUserRepo =
        PgUserRepo { pool, query_timeout: timeout }

impl UserRepository for PgUserRepo {
    async fn find_by_id(self: &PgUserRepo, id: UserId) -> Result[Option[User], DbError] =
        with guard self.pool.acquire() as conn:
            let row = conn.query_opt(
                "SELECT id, name, email, role, active FROM users WHERE id = $1",
                &[&id],
            ).await?
            Ok(row.map(|r| row_to_user(r)))

    async fn find_by_email(self: &PgUserRepo, email: &str) -> Result[Option[User], DbError] =
        with guard self.pool.acquire() as conn:
            let row = conn.query_opt(
                "SELECT id, name, email, role, active FROM users WHERE email = $1",
                &[&email],
            ).await?
            Ok(row.map(|r| row_to_user(r)))

    async fn list_active(self: &PgUserRepo, limit: i32, offset: i32) -> Result[Vec[User], DbError] =
        with guard self.pool.acquire() as conn:
            let rows = conn.query(
                "SELECT id, name, email, role, active FROM users WHERE active = true LIMIT $1 OFFSET $2",
                &[&limit, &offset],
            ).await?
            Ok(rows |> map(|r| row_to_user(r)) |> collect())

    async fn insert(self: &PgUserRepo, user: &User) -> Result[UserId, DbError] =
        with guard self.pool.acquire() as conn:
            let row = conn.query_one(
                "INSERT INTO users (name, email, role, active) VALUES ($1, $2, $3, $4) RETURNING id",
                &[&user.name, &user.email, &role_to_str(user.role), &user.active],
            ).await?
            Ok(UserId(row.get(0)))

    async fn update(self: &PgUserRepo, id: UserId, fields: &UserUpdate) -> Result[Unit, DbError] =
        with guard self.pool.acquire() as conn:
            // Build SET clause and params from non-None fields
            var sets = Vec.new()
            var params: Vec[&dyn ToSql] = vec![&id]
            var idx = 2
            if let Some(name) = &fields.name:
                sets.push("name = ${idx}")
                params.push(name)
                idx += 1
            if let Some(email) = &fields.email:
                sets.push("email = ${idx}")
                params.push(email)
                idx += 1
            if let Some(role) = &fields.role:
                sets.push("role = ${idx}")
                params.push(&role_to_str(*role))
                idx += 1
            if let Some(active) = &fields.active:
                sets.push("active = ${idx}")
                params.push(active)
                idx += 1

            if sets.is_empty() then return Ok()

            let query = "UPDATE users SET {sets.join(", ")} WHERE id = $1"
            conn.execute(&query, params.as_slice()).await?
            Ok()

    async fn delete(self: &PgUserRepo, id: UserId) -> Result[Unit, DbError] =
        with guard self.pool.acquire() as conn:
            conn.execute(
                "DELETE FROM users WHERE id = $1",
                &[&id],
            ).await?
            Ok()

    async fn count_posts(self: &PgUserRepo, id: UserId) -> Result[i32, DbError] =
        with guard self.pool.acquire() as conn:
            let row = conn.query_one(
                "SELECT COUNT(*) FROM posts WHERE author_id = $1",
                &[&id],
            ).await?
            Ok(row.get(0))

    async fn count_followers(self: &PgUserRepo, id: UserId) -> Result[i32, DbError] =
        with guard self.pool.acquire() as conn:
            let row = conn.query_one(
                "SELECT COUNT(*) FROM follows WHERE followed_id = $1",
                &[&id],
            ).await?
            Ok(row.get(0))
}

fn row_to_user(row: &Row) -> User =
    User {
        id: UserId(row.get(0)),
        name: row.get(1),
        email: row.get(2),
        role: str_to_role(row.get(3)),
        active: row.get(4),
    }

fn role_to_str(role: Role) -> &str =
    match role
        Admin     -> "admin"
        Moderator -> "moderator"
        Member    -> "member"
        Guest     -> "guest"

fn str_to_role(s: &str) -> Role =
    match s
        "admin"     -> Admin
        "moderator" -> Moderator
        "member"    -> Member
        _           -> Guest
```

### Redis Cache

```with
module app.cache.redis

use app.traits.CacheService
use app.errors.CacheError
use std.time.Duration

type RedisCache = {
    client: RedisClient,
    prefix: String,
}

extend RedisCache
    fn new(client: RedisClient, prefix: &str) -> RedisCache =
        RedisCache { client, prefix: prefix.to_string() }

    fn prefixed_key(self: &RedisCache, key: &str) -> String =
        "{self.prefix}:{key}"

impl CacheService for RedisCache {
    async fn get[T: Deserialize](self: &RedisCache, key: &str) -> Result[Option[T], CacheError] =
        let full_key = self.prefixed_key(key)
        match self.client.get(&full_key).await
            Ok(Some(bytes)) -> Ok(Some(deserialize(&bytes)?))
            Ok(None)        -> Ok(None)
            Err(e)          -> Err(CacheError.ConnectionLost)

    async fn set[T: Serialize](self: &RedisCache, key: &str, val: &T, ttl: Duration) -> Result[Unit, CacheError] =
        let full_key = self.prefixed_key(key)
        let bytes = serialize(val)
        self.client.set_ex(&full_key, &bytes, ttl.as_secs()).await?
        Ok()

    async fn delete(self: &RedisCache, key: &str) -> Result[Unit, CacheError] =
        let full_key = self.prefixed_key(key)
        self.client.del(&full_key).await?
        Ok()

    async fn exists(self: &RedisCache, key: &str) -> Result[bool, CacheError] =
        let full_key = self.prefixed_key(key)
        self.client.exists(&full_key).await
}
```

### Email Notification Service

```with
module app.notify.email

use app.traits.NotificationService
use app.domain.{Notification, Priority}
use app.errors.NotifyError

type EmailNotifier = {
    smtp_host: String,
    smtp_port: u16,
    from_addr: String,
    rate_limit: RateLimiter,
}

impl NotificationService for EmailNotifier {
    async fn send(self: &EmailNotifier, notif: &Notification) -> Result[Unit, NotifyError] =
        if not self.rate_limit.try_acquire() then
            return Err(NotifyError.RateLimited(Duration.seconds(60)))

        let email = with SmtpMessage.new() as mut msg:
            msg.from = self.from_addr.clone()
            msg.to = notif.recipient.clone()
            msg.subject = notif.subject.clone()
            msg.body = notif.body.clone()
            msg.priority = match notif.priority
                Urgent -> 1
                Normal -> 3
                Low    -> 5

        with SmtpTransport.connect(&self.smtp_host, self.smtp_port) as transport:
            transport.send(&email).await?
        Ok()

    async fn send_batch(self: &EmailNotifier, notifs: &[Notification]) -> Result[i32, NotifyError] =
        var sent = 0
        for notif in notifs:
            match self.send(notif).await
                Ok() -> sent += 1
                Err(NotifyError.RateLimited(d)) -> return Err(NotifyError.RateLimited(d))
                Err(_) -> ()  // skip individual failures
        Ok(sent)
}
```

---

## The Composed Service

This is where trait objects come together. `UserService` holds its
dependencies as `&dyn Trait` references — it doesn't know or care
about the concrete implementations. In production these are Postgres,
Redis, and SMTP. In tests they're in-memory mocks. Same code path.

```with
module app.service

use app.domain.*
use app.errors.ServiceError
use app.traits.*
use std.time.{Duration, Instant}
use std.sync.RwLock

// --- Service Configuration ---

type ServiceConfig = {
    cache_ttl: Duration,
    max_batch_size: i32,
    notify_on_create: bool,
    notify_on_delete: bool,
}

extend ServiceConfig
    fn default() -> ServiceConfig =
        ServiceConfig {
            cache_ttl: Duration.minutes(5),
            max_batch_size: 100,
            notify_on_create: true,
            notify_on_delete: false,
        }

// --- The Service ---
//
// All dependencies are trait objects. The service doesn't know
// whether it's talking to Postgres or an in-memory mock.
// This is the same pattern as Go interfaces or Java DI,
// but with zero runtime reflection and full type safety.

type UserService = {
    repo: Box[dyn UserRepository],
    cache: Box[dyn CacheService],
    notifier: Box[dyn NotificationService],
    audit: Box[dyn AuditLog],
    config: ServiceConfig,
    metrics: RwLock[ServiceMetrics],
}

type ServiceMetrics = {
    requests: i64,
    cache_hits: i64,
    cache_misses: i64,
    errors: i64,
}

extend ServiceMetrics
    fn new() -> ServiceMetrics =
        ServiceMetrics { requests: 0, cache_hits: 0, cache_misses: 0, errors: 0 }

// --- Builder (with block Form 2) ---

extend UserService
    fn builder() -> UserServiceBuilder =
        UserServiceBuilder {
            repo: None,
            cache: None,
            notifier: None,
            audit: None,
            config: ServiceConfig.default(),
        }

type UserServiceBuilder = {
    repo: Option[Box[dyn UserRepository]],
    cache: Option[Box[dyn CacheService]],
    notifier: Option[Box[dyn NotificationService]],
    audit: Option[Box[dyn AuditLog]],
    config: ServiceConfig,
}

extend UserServiceBuilder
    fn repo(self: UserServiceBuilder, r: Box[dyn UserRepository]) -> UserServiceBuilder =
        { self with repo: Some(r) }

    fn cache(self: UserServiceBuilder, c: Box[dyn CacheService]) -> UserServiceBuilder =
        { self with cache: Some(c) }

    fn notifier(self: UserServiceBuilder, n: Box[dyn NotificationService]) -> UserServiceBuilder =
        { self with notifier: Some(n) }

    fn audit(self: UserServiceBuilder, a: Box[dyn AuditLog]) -> UserServiceBuilder =
        { self with audit: Some(a) }

    fn config(self: UserServiceBuilder, cfg: ServiceConfig) -> UserServiceBuilder =
        { self with config: cfg }

    fn build(self: UserServiceBuilder) -> Result[UserService, String] =
        Ok(UserService {
            repo: self.repo.ok_or("UserRepository is required")?,
            cache: self.cache.ok_or("CacheService is required")?,
            notifier: self.notifier.ok_or("NotificationService is required")?,
            audit: self.audit.ok_or("AuditLog is required")?,
            config: self.config,
            metrics: RwLock.new(ServiceMetrics.new()),
        })

// --- Service Methods ---

extend UserService
    // --- Get Profile (cache-through pattern) ---
    //
    // 1. Check cache
    // 2. On miss, fetch from repo + enrich concurrently
    // 3. Write through to cache
    //
    // Demonstrates: trait objects, with blocks, structured concurrency,
    // pattern matching, error propagation, pipeline operators.

    async fn get_profile(self: &UserService, id: UserId) -> Result[UserProfile, ServiceError] =
        self.bump_requests()

        // Check cache first
        let cache_key = "profile:{id}"
        match self.cache.get[UserProfile](&cache_key).await
            Ok(Some(cached)) ->
                self.bump_cache_hit()
                return Ok(cached)
            Ok(None) ->
                self.bump_cache_miss()
            Err(_) ->
                // Cache errors are non-fatal — fall through to repo
                self.bump_cache_miss()

        // Cache miss — fetch user and stats concurrently
        let user = self.repo.find_by_id(id).await?
            .ok_or(ServiceError.Db(DbError.NotFound("users", "{id}")))?

        // Structured concurrency: fire off both stat queries in parallel
        let (posts, followers, last_login) = async scope |s|:
            let posts_task = s.track(self.repo.count_posts(id))
            let followers_task = s.track(self.repo.count_followers(id))
            let login_task = s.track(self.cache.get[Instant]("last_login:{id}"))

            let posts = posts_task.await?
            let followers = followers_task.await?
            let last_login = login_task.await.unwrap_or(None)

            (posts, followers, last_login)

        let profile = UserProfile {
            user,
            post_count: posts,
            followers,
            last_login,
        }

        // Write through to cache (fire and forget — don't fail on cache error)
        let _ = self.cache.set(&cache_key, &profile, self.config.cache_ttl).await

        Ok(profile)

    // --- Create User ---
    //
    // Validates, inserts, invalidates cache, sends notification,
    // records audit log. Demonstrates with-block builders, pattern
    // matching on roles, and concurrent fire-and-forget.

    async fn create_user(
        self: &UserService,
        req: CreateUserRequest,
        actor: UserId,
    ) -> Result[User, ServiceError] =
        self.bump_requests()

        // Validation
        if req.name.is_empty() then
            return Err(ServiceError.Validation("name cannot be empty"))
        if not req.email.contains("@") then
            return Err(ServiceError.Validation("invalid email address"))

        // Check for duplicate email
        if self.repo.find_by_email(&req.email).await?.is_some() then
            return Err(ServiceError.Validation("email already registered"))

        // Build the user
        let user = User {
            id: UserId(0),  // assigned by database
            name: req.name,
            email: req.email,
            role: req.role,
            active: true,
        }

        let id = self.repo.insert(&user).await?
        let user = { user with id }

        // Post-creation side effects (concurrent, non-blocking)
        async scope |s|:
            // Audit log
            s.track(self.audit.record(
                actor,
                "create_user",
                "Created user {user.name} ({user.email})",
            ))

            // Send welcome notification if configured
            if self.config.notify_on_create then
                s.track(self.send_welcome(&user))

            // Invalidate any cached user lists
            s.track(self.cache.delete("users:active:*"))

        Ok(user)

    // --- Update User ---
    //
    // Partial update via UserUpdate. Demonstrates record update syntax,
    // with-block scoped binding, and cache invalidation.

    async fn update_user(
        self: &UserService,
        id: UserId,
        update: UserUpdate,
        actor: UserId,
    ) -> Result[User, ServiceError] =
        self.bump_requests()

        // Fetch current state
        let current = self.repo.find_by_id(id).await?
            .ok_or(ServiceError.Db(DbError.NotFound("users", "{id}")))?

        // Apply partial update (clone current first — fields will be moved)
        let original = current.clone()
        let updated = User {
            id: current.id,
            name: update.name.unwrap_or(current.name),
            email: update.email.unwrap_or(current.email),
            role: update.role.unwrap_or(current.role),
            active: update.active.unwrap_or(current.active),
        }

        self.repo.update(id, &update).await?

        // Invalidate caches
        self.cache.delete("profile:{id}").await.unwrap_or(())

        // Audit
        with describe_changes(&original, &updated) as changes:
            self.audit.record(actor, "update_user", &changes).await?

        Ok(updated)

    // --- Delete User ---

    async fn delete_user(
        self: &UserService,
        id: UserId,
        actor: UserId,
    ) -> Result[Unit, ServiceError] =
        self.bump_requests()

        let user = self.repo.find_by_id(id).await?
            .ok_or(ServiceError.Db(DbError.NotFound("users", "{id}")))?

        self.repo.delete(id).await?
        self.cache.delete("profile:{id}").await.unwrap_or(())

        async scope |s|:
            s.track(self.audit.record(
                actor,
                "delete_user",
                "Deleted user {user.name} ({user.email})",
            ))

            if self.config.notify_on_delete then
                s.track(self.notifier.send(&Notification {
                    recipient: user.email.clone(),
                    subject: "Account deleted",
                    body: "Your account has been removed.",
                    priority: Normal,
                }))

        Ok()

    // --- List Active Users (paginated) ---

    async fn list_active(
        self: &UserService,
        page: i32,
        per_page: i32,
    ) -> Result[Vec[User], ServiceError] =
        self.bump_requests()

        let limit = per_page.clamp(1, self.config.max_batch_size)
        let offset = (page - 1) * limit

        // Try cache for first page
        if page == 1 then
            match self.cache.get[Vec[User]]("users:active:page1").await
                Ok(Some(cached)) ->
                    self.bump_cache_hit()
                    return Ok(cached)
                _ -> ()

        let users = self.repo.list_active(limit, offset).await?

        // Cache first page
        if page == 1 then
            let _ = self.cache.set(
                "users:active:page1",
                &users,
                self.config.cache_ttl,
            ).await

        Ok(users)

    // --- Batch Profile Fetch ---
    //
    // Demonstrates structured concurrency with many parallel tasks,
    // traverse combinator, and pipeline composition.

    async fn get_profiles_batch(
        self: &UserService,
        ids: Vec[UserId],
    ) -> Result[Vec[UserProfile], ServiceError] =
        self.bump_requests()

        async scope |s|:
            let tasks = ids
                |> map(|id| s.track(self.get_profile(id)))
                |> collect[Vec]()
            let results = tasks.iter()
                |> map(|task| task.await)
                |> collect[Vec]()
            results |> traverse(|r| r)    // Vec[Result] → Result[Vec]

    // --- Internal Helpers ---

    async fn send_welcome(self: &UserService, user: &User) -> Result[Unit, NotifyError] =
        let body: str = match user.role
            Admin     -> "Welcome, administrator. Full access granted."
            Moderator -> "Welcome, moderator. You can manage content."
            Member    -> "Welcome to the platform, {user.name}!"
            Guest     -> "You've been added as a guest."

        self.notifier.send(&Notification {
            recipient: user.email.clone(),
            subject: "Welcome to the platform",
            body,
            priority: Normal,
        })
        .await

    fn bump_requests(self: &UserService) =
        with guard self.metrics.write() as mut m:
            m.requests += 1

    fn bump_cache_hit(self: &UserService) =
        with guard self.metrics.write() as mut m:
            m.cache_hits += 1

    fn bump_cache_miss(self: &UserService) =
        with guard self.metrics.write() as mut m:
            m.cache_misses += 1

fn describe_changes(old: &User, new: &User) -> String =
    with Vec.new() as mut changes:
        if old.name != new.name then
            changes.push("name: '{old.name}' → '{new.name}'")
        if old.email != new.email then
            changes.push("email: '{old.email}' → '{new.email}'")
        if old.role != new.role then
            changes.push("role changed")
        if old.active != new.active then
            changes.push(if new.active then "activated" else "deactivated")
        changes.join(", ")
```

---

## HTTP Handler Layer

Wires the service to HTTP endpoints. Demonstrates pipeline
composition and the `with` block as the universal entry point
for scoped interaction.

```with
module app.http

use app.service.UserService
use app.domain.*
use app.errors.ServiceError
use std.sync.Arc

type AppState = {
    service: Arc[UserService],
}

async fn handle_request(state: &AppState, req: HttpRequest) -> HttpResponse =
    match (req.method(), req.path_str())
        ("GET",    "/users")     -> handle_list(state, &req) .await
        ("GET",    "/users/{id}") -> handle_get_profile(state, req.param("id")) .await
        ("POST",   "/users")     -> handle_create(state, &req) .await
        ("PUT",    "/users/{id}") -> handle_update(state, &req, req.param("id")) .await
        ("DELETE", "/users/{id}") -> handle_delete(state, &req, req.param("id")) .await
        _ -> HttpResponse.not_found()

async fn handle_get_profile(state: &AppState, id_str: &str) -> HttpResponse =
    let id = match id_str.parse_int()
        Ok(n)  -> UserId(n)
        Err(_) -> return HttpResponse.bad_request("invalid user id")

    match state.service.get_profile(id).await
        Ok(profile)                               -> HttpResponse.json(200, &profile)
        Err(ServiceError.Db(DbError.NotFound(..))) -> HttpResponse.not_found()
        Err(ServiceError.Validation(msg))          -> HttpResponse.bad_request(&msg)
        Err(e)                                     -> HttpResponse.internal_error(&e.to_string())

async fn handle_list(state: &AppState, req: &HttpRequest) -> HttpResponse =
    let page = req.query_param("page")
        .and_then(|s| s.parse_int().ok())
        .unwrap_or(1)
    let per_page = req.query_param("per_page")
        .and_then(|s| s.parse_int().ok())
        .unwrap_or(20)

    match state.service.list_active(page, per_page).await
        Ok(users) -> HttpResponse.json(200, &users)
        Err(e)    -> HttpResponse.internal_error(&e.to_string())

async fn handle_create(state: &AppState, req: &HttpRequest) -> HttpResponse =
    let body = match req.json[CreateUserRequest]()
        Ok(b)  -> b
        Err(_) -> return HttpResponse.bad_request("invalid request body")

    // Actor ID from auth middleware (stored in request extensions)
    let actor = req.extension[UserId]().unwrap_or(UserId(0))

    match state.service.create_user(body, actor).await
        Ok(user) -> HttpResponse.json(201, &user)
        Err(ServiceError.Validation(msg)) -> HttpResponse.bad_request(&msg)
        Err(e) -> HttpResponse.internal_error(&e.to_string())

async fn handle_update(state: &AppState, req: &HttpRequest, id_str: &str) -> HttpResponse =
    let id = match id_str.parse_int()
        Ok(n)  -> UserId(n)
        Err(_) -> return HttpResponse.bad_request("invalid user id")

    let update = match req.json[UserUpdate]()
        Ok(u)  -> u
        Err(_) -> return HttpResponse.bad_request("invalid request body")

    let actor = req.extension[UserId]().unwrap_or(UserId(0))

    match state.service.update_user(id, update, actor).await
        Ok(user)                                   -> HttpResponse.json(200, &user)
        Err(ServiceError.Db(DbError.NotFound(..))) -> HttpResponse.not_found()
        Err(ServiceError.Validation(msg))          -> HttpResponse.bad_request(&msg)
        Err(e)                                     -> HttpResponse.internal_error(&e.to_string())

async fn handle_delete(state: &AppState, req: &HttpRequest, id_str: &str) -> HttpResponse =
    let id = match id_str.parse_int()
        Ok(n)  -> UserId(n)
        Err(_) -> return HttpResponse.bad_request("invalid user id")

    let actor = req.extension[UserId]().unwrap_or(UserId(0))

    match state.service.delete_user(id, actor).await
        Ok()                                     -> HttpResponse.no_content()
        Err(ServiceError.Db(DbError.NotFound(..))) -> HttpResponse.not_found()
        Err(e)                                     -> HttpResponse.internal_error(&e.to_string())
```

---

## Main (wiring it all together)

```with
module app.main

use app.service.{UserService, ServiceConfig}
use app.repo.postgres.PgUserRepo
use app.cache.redis.RedisCache
use app.notify.email.EmailNotifier
use app.http.{AppState, handle_request}
use std.sync.Arc
use std.time.Duration

async fn main() -> Result[Unit, ServiceError] =
    // Configuration (with block Form 2: builder)
    let config = with ServiceConfig.default() as mut c:
        c.cache_ttl = Duration.minutes(10)
        c.notify_on_create = true
        c.notify_on_delete = true
        c.max_batch_size = 50

    // Initialize infrastructure
    let db_pool = ConnectionPool.connect("postgres://localhost/myapp", 20).await?
    let redis = RedisClient.connect("redis://localhost:6379").await?

    // Compose the service from trait objects
    let service = UserService.builder()
        .repo(Box.new(PgUserRepo.new(db_pool, Duration.seconds(5))))
        .cache(Box.new(RedisCache.new(redis, "myapp")))
        .notifier(Box.new(EmailNotifier {
            smtp_host: "smtp.example.com",
            smtp_port: 587,
            from_addr: "noreply@example.com",
            rate_limit: RateLimiter.new(100, Duration.minutes(1)),
        }))
        .audit(Box.new(PgAuditLog.new(db_pool.clone())))
        .config(config)
        .build()?

    let state = Arc.new(AppState { service: Arc.new(service) })

    // Start server
    let listener = std.net.TcpListener.bind("0.0.0.0:8080").await?
    println("Listening on :8080")

    loop:
        let conn = listener.accept().await?
        let state = state.clone()
        // state is moved into the spawned fiber — no dangling reference
        spawn handle_connection(state, conn)
```

---

## Test Suite (in-memory mocks)

The entire service layer is testable with no database, no Redis,
no SMTP server. Trait objects make this trivial.

```with
module app.tests

use app.domain.*
use app.errors.*
use app.traits.*
use app.service.{UserService, ServiceConfig}
use std.sync.{RwLock, Mutex}
use std.collections.HashMap
use std.time.Duration

// --- In-Memory Mock Repository ---

type MockUserRepo = {
    users: RwLock[HashMap[UserId, User]],
    next_id: Mutex[i64],
}

extend MockUserRepo
    fn new() -> MockUserRepo =
        MockUserRepo {
            users: RwLock.new(HashMap.new()),
            next_id: Mutex.new(1),
        }

impl UserRepository for MockUserRepo {
    async fn find_by_id(self: &MockUserRepo, id: UserId) -> Result[Option[User], DbError] =
        with guard self.users.read() as users:
            Ok(users.get(&id).cloned())

    async fn find_by_email(self: &MockUserRepo, email: &str) -> Result[Option[User], DbError] =
        with guard self.users.read() as users:
            Ok(users.values()
                |> find(|u| u.email == email)
                |> map(|u| u.clone()))

    async fn list_active(self: &MockUserRepo, limit: i32, offset: i32) -> Result[Vec[User], DbError] =
        with guard self.users.read() as users:
            Ok(users.values()
                |> filter(|u| u.active)
                |> skip(offset as usize)
                |> take(limit as usize)
                |> cloned()
                |> collect())

    async fn insert(self: &MockUserRepo, user: &User) -> Result[UserId, DbError] =
        let id = with guard self.next_id.lock() as mut next:
            let id = UserId(*next)
            *next += 1
            id
        let user = { user.clone() with id }
        with guard self.users.write() as mut users:
            users.insert(id, user)
        Ok(id)

    async fn update(self: &MockUserRepo, id: UserId, fields: &UserUpdate) -> Result[Unit, DbError] =
        with guard self.users.write() as mut users:
            match users.get_mut(&id)
                Some(user) ->
                    if let Some(name) = &fields.name then user.name = name.clone()
                    if let Some(email) = &fields.email then user.email = email.clone()
                    if let Some(role) = &fields.role then user.role = *role
                    if let Some(active) = &fields.active then user.active = *active
                    Ok()
                None -> Err(DbError.NotFound("users", "{id}"))

    async fn delete(self: &MockUserRepo, id: UserId) -> Result[Unit, DbError] =
        with guard self.users.write() as mut users:
            users.remove(&id)
                .map(|_| ())
                .ok_or(DbError.NotFound("users", "{id}"))

    async fn count_posts(self: &MockUserRepo, _id: UserId) -> Result[i32, DbError] =
        Ok(0)

    async fn count_followers(self: &MockUserRepo, _id: UserId) -> Result[i32, DbError] =
        Ok(0)
}

// --- In-Memory Mock Cache ---

type MockCache = {
    store: RwLock[HashMap[String, Vec[u8]]],
}

extend MockCache
    fn new() -> MockCache =
        MockCache { store: RwLock.new(HashMap.new()) }

impl CacheService for MockCache {
    async fn get[T: Deserialize](self: &MockCache, key: &str) -> Result[Option[T], CacheError] =
        with guard self.store.read() as store:
            match store.get(key)
                Some(bytes) -> Ok(Some(deserialize(bytes)?))
                None        -> Ok(None)

    async fn set[T: Serialize](self: &MockCache, key: &str, val: &T, _ttl: Duration) -> Result[Unit, CacheError] =
        with guard self.store.write() as mut store:
            store.insert(key.to_string(), serialize(val))
        Ok()

    async fn delete(self: &MockCache, key: &str) -> Result[Unit, CacheError] =
        with guard self.store.write() as mut store:
            store.remove(key)
        Ok()

    async fn exists(self: &MockCache, key: &str) -> Result[bool, CacheError] =
        with guard self.store.read() as store:
            Ok(store.contains_key(key))
}

// --- Recording Mock Notifier ---

type MockNotifier = {
    sent: Mutex[Vec[Notification]],
}

extend MockNotifier
    fn new() -> MockNotifier =
        MockNotifier { sent: Mutex.new(Vec.new()) }

    fn sent_count(self: &MockNotifier) -> i32 =
        with guard self.sent.lock() as sent:
            sent.len() as i32

impl NotificationService for MockNotifier {
    async fn send(self: &MockNotifier, notif: &Notification) -> Result[Unit, NotifyError] =
        with guard self.sent.lock() as mut sent:
            sent.push(notif.clone())
        Ok()

    async fn send_batch(self: &MockNotifier, notifs: &[Notification]) -> Result[i32, NotifyError] =
        with guard self.sent.lock() as mut sent:
            let count = notifs.len() as i32
            for n in notifs:
                sent.push(n.clone())
            Ok(count)
}

// --- No-Op Audit Log ---

type MockAudit = {}

impl AuditLog for MockAudit {
    async fn record(self: &MockAudit, _actor: UserId, _action: &str, _detail: &str) -> Result[Unit, DbError] =
        Ok()
}

// --- Test Helper: Build service with mocks ---

fn test_service() -> (UserService, &MockUserRepo, &MockNotifier) =
    let repo = Box.new(MockUserRepo.new())
    let notifier = Box.new(MockNotifier.new())

    // Keep references to mocks for assertions
    let repo_ref = &*repo as &MockUserRepo
    let notifier_ref = &*notifier as &MockNotifier

    let service = UserService.builder()
        .repo(repo)
        .cache(Box.new(MockCache.new()))
        .notifier(notifier)
        .audit(Box.new(MockAudit {}))
        .build().unwrap()

    (service, repo_ref, notifier_ref)

// --- Tests ---

async fn test_create_and_fetch_user() =
    let (svc, _, notifier) = test_service()

    let req = CreateUserRequest {
        name: "Alice",
        email: "alice@example.com",
        role: Member,
    }

    // Create
    let user = svc.create_user(req, UserId(0)).await.unwrap()
    assert(user.name == "Alice")
    assert(user.email == "alice@example.com")
    assert(user.active == true)

    // Welcome email was sent
    assert(notifier.sent_count() == 1)

    // Fetch profile
    let profile = svc.get_profile(user.id).await.unwrap()
    assert(profile.user.name == "Alice")
    assert(profile.post_count == 0)
    assert(profile.followers == 0)

async fn test_duplicate_email_rejected() =
    let (svc, _, _) = test_service()

    let req = CreateUserRequest {
        name: "Alice",
        email: "alice@example.com",
        role: Member,
    }

    // First create succeeds
    svc.create_user(req.clone(), UserId(0)).await.unwrap()

    // Second create with same email fails
    match svc.create_user(req, UserId(0)).await
        Err(ServiceError.Validation(msg)) ->
            assert(msg.contains("already registered"))
        other -> unreachable("expected Validation error, got {other}")

async fn test_update_partial_fields() =
    let (svc, _, _) = test_service()

    let user = svc.create_user(CreateUserRequest {
        name: "Bob",
        email: "bob@example.com",
        role: Member,
    }, UserId(0)).await.unwrap()

    // Update only the name
    let updated = svc.update_user(user.id, UserUpdate {
        name: Some("Robert"),
        email: None,
        role: None,
        active: None,
    }, UserId(0)).await.unwrap()

    assert(updated.name == "Robert")
    assert(updated.email == "bob@example.com")  // unchanged
    assert(updated.role == Member)              // unchanged

async fn test_delete_user() =
    let (svc, _, _) = test_service()

    let user = svc.create_user(CreateUserRequest {
        name: "Charlie",
        email: "charlie@example.com",
        role: Guest,
    }, UserId(0)).await.unwrap()

    svc.delete_user(user.id, UserId(0)).await.unwrap()

    // Profile should now 404
    assert_matches(svc.get_profile(user.id).await, Err(ServiceError.Db(DbError.NotFound(..))))

async fn test_cache_hit_on_second_fetch() =
    let (svc, _, _) = test_service()

    let user = svc.create_user(CreateUserRequest {
        name: "Diana",
        email: "diana@example.com",
        role: Admin,
    }, UserId(0)).await.unwrap()

    // First fetch — cache miss, hits repo
    let p1 = svc.get_profile(user.id).await.unwrap()

    // Second fetch — should be cached
    let p2 = svc.get_profile(user.id).await.unwrap()

    assert(p1.user.name == p2.user.name)

    // Verify metrics
    with svc.metrics.read() as m:
        assert(m.cache_misses >= 1)
        assert(m.cache_hits >= 1)

async fn test_batch_profiles() =
    let (svc, _, _) = test_service()

    // Create 5 users
    let ids = with Vec.new() as mut ids:
        for i in 0..5:
            let user = svc.create_user(CreateUserRequest {
                name: "User {i}",
                email: "user{i}@example.com",
                role: Member,
            }, UserId(0)).await.unwrap()
            ids.push(user.id)
        ids

    // Batch fetch all profiles
    let profiles = svc.get_profiles_batch(ids).await.unwrap()
    assert(profiles.len() == 5)
```

---

## Feature Inventory

This example exercises the following spec features:

| Feature | Spec Section | Where Used |
|---------|-------------|------------|
| Trait definitions with async methods | §11.5 | All four service traits |
| Trait objects (`dyn Trait`) | §11.3 | `Box[dyn UserRepository]`, etc. |
| `with` Form 1: guarded access | §7.1 | `with guard self.pool.acquire() as conn:`, `with guard self.users.read() as users:` |
| `with` Form 2: builder pattern | §7.2 | `with Vec.new() as mut parts:` |
| `with` Form 3: scoped binding | §7.3 | `with describe_changes(...) as changes:` |
| `with` Form 4: record update | §7.4 | `{ user with id }`, `{ self with repo: ... }` |
| `@[no_await_guard]` rule | §7.9 | Locks use `with` without `.await`; pools use `with` with `.await` |
| `?` error propagation | §10.2 | Throughout all service methods |
| Structured concurrency (`s.track`) | §14.8 | `async scope` in get_profile, create_user |
| Pipeline operator `\|>` | §9.6 | Collection operations |
| By-value `self` method chaining | §9.5 | Builder construction in main and tests |
| Pattern matching | §9.7 | Error routing in HTTP handlers |
| Distinct types | §4.5 | `type UserId = distinct i64` |
| Enum variants | §4.4 | `Role`, `Priority`, all error types |
| `error` declarations | §10.6 | All error types with `From` impls |
| `RwLock` as `Scoped`/`ScopedMut` | §18.6 | Metrics, mock collections |
| Immutable by default | §2 | `let` everywhere, `var` only where needed |
| `async fn` returns `Task[T]` | §14.4 | All service methods |
| Cancellation via `TaskCancelled` | §14.6 | `From[TaskCancelled]` impl |
| `@[must_use]` on Result/Task | §10.1, §14.6 | All fallible calls use `?` or `let _` |
| `sequence` / `traverse` | §10.5 | Batch profile fetch |
| `.unwrap()` / `.expect()` | §10.6 | Test assertions |
| `unreachable()` | §18.6 | Test match arms for unexpected cases |
| `assert_matches` | §18.6 | Test pattern matching on results |
| `.to_owned()` on string literals | §15.3 | Explicit string allocation |
| Unit elision | §4.8 | `Ok()` instead of `Ok(())` throughout |
| Postfix `.await` | §14.5 | All async calls |
| Implicit builder return | §7.2 | `with ... as mut` blocks auto-return |
