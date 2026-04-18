module service

use domain.*
use errors.*

// --- Service Configuration ---

type ServiceConfig {
    cache_ttl_secs: i64 = 300,
    max_batch_size: i32 = 100,
    notify_on_create: bool = true,
    notify_on_delete: bool = false,
}

// --- Service Metrics ---

type ServiceMetrics {
    requests: i64 = 0,
    cache_hits: i64 = 0,
    cache_misses: i64 = 0,
    errors: i64 = 0,
}

// --- The Service ---
//
// Demonstrates service-layer architecture with configuration,
// metrics tracking, builder pattern, and domain logic.

type UserService {
    config: ServiceConfig,
    metrics: ServiceMetrics,
}

// --- Builder Pattern ---

type UserServiceBuilder {
    config: ServiceConfig,
}

extend UserService:
    fn builder -> UserServiceBuilder:
        UserServiceBuilder {
            config: ServiceConfig {},
        }

extend UserServiceBuilder:
    fn with_config(self: UserServiceBuilder, cfg: ServiceConfig) -> UserServiceBuilder:
        { self with config: cfg }

    fn build(self: UserServiceBuilder) -> UserService:
        UserService {
            config: self.config,
            metrics: ServiceMetrics {},
        }

// --- Service Methods ---

extend UserService:

    // --- Validate a create request ---

    fn validate_create(self: &UserService, req: CreateUserRequest) -> Option[str]:
        if req.name == "":
            return Some("name cannot be empty")
        if not req.email.contains("@"):
            return Some("invalid email address")
        None

    // --- Create User ---
    //
    // Validates and builds a user from a request.
    // In a real service, this would insert into a database
    // and send notifications.

    fn create_user(
        self: &mut UserService,
        req: CreateUserRequest,
        actor: UserId,
    ) -> User:
        self.metrics.requests = self.metrics.requests + 1

        // Build the user -- active defaults to true via default field value
        User {
            id: UserId { value: 0 },
            name: req.name,
            email: req.email,
            role: req.role,
        }

    // --- Build a profile from a user ---

    fn make_profile(self: &UserService, user: User, posts: i32, followers: i32) -> UserProfile:
        UserProfile {
            user,
            post_count: posts,
            followers,
        }

    // --- Clamp pagination ---

    fn clamp_page_size(self: &UserService, per_page: i32) -> i32:
        if per_page > self.config.max_batch_size:
            self.config.max_batch_size
        else if per_page < 1:
            1
        else:
            per_page

    // --- Generate welcome message based on role ---

    fn welcome_body(self: &UserService, role: Role) -> str:
        match role:
            .Admin     => "Welcome, administrator. Full access granted."
            .Moderator => "Welcome, moderator. You can manage content."
            .Member    => "Welcome to the platform!"
            .Guest     => "You've been added as a guest."

    // --- Build a notification ---

    fn make_welcome_notification(self: &UserService, user: User) -> Notification:
        Notification {
            recipient: user.email,
            subject: "Welcome to the platform",
            body: self.welcome_body(user.role),
            priority: .Normal,
        }

    // --- Bump metrics ---

    fn bump_requests(self: &mut UserService):
        self.metrics.requests = self.metrics.requests + 1

    fn bump_cache_hit(self: &mut UserService):
        self.metrics.cache_hits = self.metrics.cache_hits + 1

    fn bump_cache_miss(self: &mut UserService):
        self.metrics.cache_misses = self.metrics.cache_misses + 1

// --- Helper: describe changes between two users ---

fn describe_changes(old: User, new_user: User) -> str:
    with Vec.new() as mut changes:
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
