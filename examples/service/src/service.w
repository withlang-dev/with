module app.service

use app.domain.*
use app.errors.ServiceError
use app.traits.*
use std.time.{Duration, Instant}
use std.sync.RwLock

// --- Service Configuration ---

type ServiceConfig = {
    cache_ttl: Duration = Duration.minutes(5),
    max_batch_size: i32 = 100,
    notify_on_create: bool = true,
    notify_on_delete: bool = false,
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
    requests: i64 = 0,
    cache_hits: i64 = 0,
    cache_misses: i64 = 0,
    errors: i64 = 0,
}

// --- Builder (with block Form 2) ---

type UserServiceBuilder = {
    repo: Option[Box[dyn UserRepository]],
    cache: Option[Box[dyn CacheService]],
    notifier: Option[Box[dyn NotificationService]],
    audit: Option[Box[dyn AuditLog]],
    config: ServiceConfig,
}

extend UserService:
    fn builder -> UserServiceBuilder:
        UserServiceBuilder {
            repo: None,
            cache: None,
            notifier: None,
            audit: None,
            config: ServiceConfig {},
        }

extend UserServiceBuilder:
    fn repo(self: UserServiceBuilder, r: Box[dyn UserRepository]) -> UserServiceBuilder:
        { self with repo: Some(r) }

    fn cache(self: UserServiceBuilder, c: Box[dyn CacheService]) -> UserServiceBuilder:
        { self with cache: Some(c) }

    fn notifier(self: UserServiceBuilder, n: Box[dyn NotificationService]) -> UserServiceBuilder:
        { self with notifier: Some(n) }

    fn audit(self: UserServiceBuilder, a: Box[dyn AuditLog]) -> UserServiceBuilder:
        { self with audit: Some(a) }

    fn config(self: UserServiceBuilder, cfg: ServiceConfig) -> UserServiceBuilder:
        { self with config: cfg }

    fn build(self: UserServiceBuilder) -> Result[UserService, str]:
        UserService {
            repo: self.repo ?? return Err("UserRepository is required"),
            cache: self.cache ?? return Err("CacheService is required"),
            notifier: self.notifier ?? return Err("NotificationService is required"),
            audit: self.audit ?? return Err("AuditLog is required"),
            config: self.config,
            metrics: RwLock.new(ServiceMetrics {}),
        })

// --- Service Methods ---

extend UserService:
    // --- Get Profile (cache-through pattern) ---
    //
    // 1. Check cache
    // 2. On miss, fetch from repo + enrich concurrently
    // 3. Write through to cache
    //
    // Demonstrates: trait objects, with blocks, structured concurrency,
    // pattern matching, error propagation, pipeline operators.

    async fn get_profile(self: &UserService, id: UserId) -> Result[UserProfile, ServiceError]:
        self.bump_requests()

        // Check cache first
        let cache_key = "profile:{id}"
        match cache_get[UserProfile](&*self.cache, &cache_key).await
            Ok(Some(cached)) ->
                self.bump_cache_hit()
                return cached
            Ok(None) ->
                self.bump_cache_miss()
            Err(_) ->
                // Cache errors are non-fatal — fall through to repo
                self.bump_cache_miss()

        // Cache miss — fetch user
        let user = self.repo.find_by_id(id).await?
            ?? return Err(.Db(.NotFound("users", "{id}")))

        // Structured concurrency: fire off stat queries in parallel
        let (posts, followers, last_login) = async scope |s|:
            let posts_task = s.track(self.repo.count_posts(id))
            let followers_task = s.track(self.repo.count_followers(id))
            let login_task = s.track(cache_get[Instant](&*self.cache, "last_login:{id}"))

            let posts = posts_task.await?
            let followers = followers_task.await?
            let last_login = login_task.await.unwrap_or(Ok(None))

            (posts, followers, last_login)

        let profile = UserProfile { user, post_count: posts, followers, last_login }

        // Write through to cache (fire and forget — don't fail on cache error)
        let _ = cache_set(&*self.cache, &cache_key, &profile, self.config.cache_ttl).await

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
    ) -> Result[User, ServiceError]:
        self.bump_requests()

        // Validation
        if req.name.is_empty() then
            return Err(.Validation("name cannot be empty"))
        if not req.email.contains("@") then
            return Err(.Validation("invalid email address"))

        // Check for duplicate email
        if self.repo.find_by_email(&req.email).await?.is_some() then
            return Err(.Validation("email already registered"))

        // Build the user — active defaults to true via default field value
        let user = User {
            id: UserId(0),  // assigned by database
            name: req.name,
            email: req.email,
            role: req.role,
        }

        let id = self.repo.insert(&user).await?
        let user = { user with id: id }

        // Post-creation side effects (concurrent, non-blocking)
        async scope |s|:
            // Audit log
            s.track(self.audit.record(
                actor, "create_user", "Created user {user.name} ({user.email})",
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
    ) -> Result[User, ServiceError]:
        self.bump_requests()

        // Fetch current state
        let current = self.repo.find_by_id(id).await?
            ?? return Err(.Db(.NotFound("users", "{id}")))

        // Apply partial update
        let updated = User {
            id: current.id,
            name: update.name.unwrap_or(current.name),
            email: update.email.unwrap_or(current.email),
            role: update.role.unwrap_or(current.role),
            active: update.active.unwrap_or(current.active),
        }

        self.repo.update(id, &update).await?

        // Invalidate caches
        self.cache.delete("profile:{id}").await.unwrap_or()

        // Audit
        with describe_changes(&current, &updated) as changes:
            self.audit.record(actor, "update_user", &changes).await?

        Ok(updated)

    // --- Delete User ---

    async fn delete_user(
        self: &UserService,
        id: UserId,
        actor: UserId,
    ) -> Result[Unit, ServiceError]:
        self.bump_requests()

        let user = self.repo.find_by_id(id).await?
            ?? return Err(.Db(.NotFound("users", "{id}")))

        self.repo.delete(id).await?
        self.cache.delete("profile:{id}").await.unwrap_or()

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
                    priority: .Normal,
                }))

        Ok()

    // --- List Active Users (paginated) ---

    async fn list_active(
        self: &UserService,
        page: i32,
        per_page: i32,
    ) -> Result[Vec[User], ServiceError]:
        self.bump_requests()

        let limit = per_page.clamp(1, self.config.max_batch_size)
        let offset = (page - 1) * limit

        // Try cache for first page
        if page == 1 then
            match cache_get[Vec[User]](&*self.cache, "users:active:page1").await
                Ok(Some(cached)) ->
                    self.bump_cache_hit()
                    return cached
                _ -> ()

        let users = self.repo.list_active(limit, offset).await?

        // Cache first page
        if page == 1 then
            let _ = cache_set(
                &*self.cache,
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
    ) -> Result[Vec[UserProfile], ServiceError]:
        self.bump_requests()

        async scope |s|:
            ids |> map(|id| s.track(self.get_profile(id)))
                |> collect[Vec]()
                |> map(|task| task.await)
                |> collect[Vec]()
                |> traverse(|r| r)    // Vec[Result] -> Result[Vec]

    // --- Internal Helpers ---

    async fn send_welcome(self: &UserService, user: &User) -> Result[Unit, NotifyError]:
        let body = match user.role
            .Admin     -> "Welcome, administrator. Full access granted."
            .Moderator -> "Welcome, moderator. You can manage content."
            .Member    -> "Welcome to the platform, {user.name}!"
            .Guest     -> "You've been added as a guest."

        self.notifier.send(&Notification {
            recipient: user.email.clone(),
            subject: "Welcome to the platform",
            body,
            priority: .Normal,
        }).await

    fn bump_requests(self: &UserService):
        with self.metrics.write() as mut m:
            m.requests += 1

    fn bump_cache_hit(self: &UserService):
        with self.metrics.write() as mut m:
            m.cache_hits += 1

    fn bump_cache_miss(self: &UserService):
        with self.metrics.write() as mut m:
            m.cache_misses += 1

fn describe_changes(old: &User, new: &User) -> str:
    with Vec.new() as mut changes:
        if old.name != new.name then
            changes.push("name: '{old.name}' -> '{new.name}'")
        if old.email != new.email then
            changes.push("email: '{old.email}' -> '{new.email}'")
        if old.role != new.role then
            changes.push("role changed")
        if old.active != new.active then
            changes.push(if new.active then "activated" else "deactivated")
        changes.join(", ")
