module service

use domain.*
use errors.*

// --- Service Configuration ---

pub type ServiceConfig {
    cache_ttl_secs: i64 = 300,
    max_batch_size: i32 = 100,
    notify_on_create: bool = true,
    notify_on_delete: bool = false,
}

// --- Service Metrics ---

pub type ServiceMetrics {
    requests: i64 = 0,
    cache_hits: i64 = 0,
    cache_misses: i64 = 0,
    errors: i64 = 0,
}

// --- The Service ---
//
// Demonstrates service-layer architecture with configuration,
// metrics tracking, builder pattern, and domain logic.

pub type UserService {
    config: ServiceConfig,
    metrics: ServiceMetrics,
}

// --- Builder Pattern ---
//
// The setters consume the builder (`move fn`, §3.1) and return the next
// one, so the chain reads `UserService.builder().with_config(cfg).build()`
// without naming the intermediate builder.

pub type UserServiceBuilder {
    config: ServiceConfig,
}

pub fn UserService.builder() -> UserServiceBuilder:
    UserServiceBuilder {
        config: ServiceConfig {},
    }

extend UserServiceBuilder:
    pub move fn with_config(cfg: ServiceConfig) -> UserServiceBuilder:
        { self with config: cfg }

    pub move fn build() -> UserService:
        UserService {
            config: self.config,
            metrics: ServiceMetrics {},
        }

// --- Service Methods ---

extend UserService:

    // --- Validate a create request ---
    //
    // Observes the request (`&T`, §3.8): the caller keeps it for create_user.

    pub fn validate_create(req: &CreateUserRequest) -> Option[str]:
        if req.name == "":
            return Some("name cannot be empty")
        if not req.email.contains("@"):
            return Some("invalid email address")
        None

    // --- Create User ---
    //
    // Validates and builds a user from a request. The request is
    // consumed and its fields move into the user (§2.2).
    // In a real service, this would insert into a database
    // and send notifications.

    pub mut fn create_user(req: CreateUserRequest, actor: UserId) -> User:
        self.metrics.requests += 1

        // Build the user -- active defaults to true via default field value.
        // A field vacates only from a `var` base (§2.2, D32).
        var request = req
        User {
            id: UserId { value: 0 },
            name: move request.name,
            email: move request.email,
            role: request.role,
        }

    // --- Build a profile from a user ---

    pub fn make_profile(user: User, posts: i32, followers: i32) -> UserProfile:
        UserProfile {
            user,
            post_count: posts,
            followers,
        }

    // --- Clamp pagination ---

    pub fn clamp_page_size(per_page: i32) -> i32:
        if per_page > self.config.max_batch_size:
            self.config.max_batch_size
        else if per_page < 1:
            1
        else:
            per_page

    // --- Generate welcome message based on role ---

    pub fn welcome_body(role: Role) -> str:
        match role:
            .Admin     => "Welcome, administrator. Full access granted."
            .Moderator => "Welcome, moderator. You can manage content."
            .Member    => "Welcome to the platform!"
            .Guest     => "You've been added as a guest."

    // --- Build a notification ---

    pub fn make_welcome_notification(user: &User) -> Notification:
        Notification {
            recipient: user.email.clone(),
            subject: "Welcome to the platform",
            body: self.welcome_body(user.role),
            priority: .Normal,
        }

    // --- Bump metrics ---

    pub mut fn bump_requests():
        self.metrics.requests += 1

    pub mut fn bump_cache_hit():
        self.metrics.cache_hits += 1

    pub mut fn bump_cache_miss():
        self.metrics.cache_misses += 1

// --- Helper: describe changes between two users ---
//
// (`with Vec.new() as mut changes:` is the builder spelling, §7.2; the
// `var` desugaring is used until #1298 accepts a trailing `if`.)

pub fn describe_changes(old: &User, new_user: &User) -> str:
    var changes = Vec.new()
    if old.name != new_user.name:
        changes.push("name changed")
    if old.email != new_user.email:
        changes.push("email changed")
    if old.active != new_user.active:
        if new_user.active:
            changes.push("activated")
        else:
            changes.push("deactivated")
    changes.join(", ")
