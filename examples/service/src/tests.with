module tests

use domain.*
use service.*

// --- Tests ---
//
// Demonstrates:
//   - Builder pattern usage
//   - Domain type construction with defaults
//   - Enum variant shorthand (.Member, .Admin, etc.)
//   - Record update syntax
//   - f-string interpolation
//   - assert for test verification

fn test_create_user:
    var service = UserService.builder().build()
    let actor = UserId { value: 0 }

    let req = CreateUserRequest {
        name: "Alice",
        email: "alice@example.com",
        role: .Member,
    }

    let user = service.create_user(req, actor)
    assert(user.name == "Alice")
    assert(user.email == "alice@example.com")

fn test_validation:
    let service = UserService.builder().build()

    // Empty name should fail
    let bad_name = CreateUserRequest {
        name: "",
        email: "alice@example.com",
        role: .Member,
    }
    match service.validate_create(bad_name):
        Some(msg) => assert(msg == "name cannot be empty")
        None => assert(false)

    // Missing @ should fail
    let bad_email = CreateUserRequest {
        name: "Alice",
        email: "no-at-sign",
        role: .Member,
    }
    match service.validate_create(bad_email):
        Some(msg) => assert(msg == "invalid email address")
        None => assert(false)

    // Valid request should pass
    let good = CreateUserRequest {
        name: "Alice",
        email: "alice@example.com",
        role: .Member,
    }
    match service.validate_create(good):
        Some(_) => assert(false)
        None => assert(true)

fn test_welcome_messages:
    let service = UserService.builder().build()

    assert(service.welcome_body(.Admin) == "Welcome, administrator. Full access granted.")
    assert(service.welcome_body(.Moderator) == "Welcome, moderator. You can manage content.")
    assert(service.welcome_body(.Member) == "Welcome to the platform!")
    assert(service.welcome_body(.Guest) == "You've been added as a guest.")

fn test_clamp_page_size:
    let config = ServiceConfig {
        max_batch_size: 50,
    }
    let builder = UserService.builder()
    let builder2 = builder.with_config(config)
    let service = builder2.build()

    // Too large
    assert(service.clamp_page_size(100) == 50)

    // Too small
    assert(service.clamp_page_size(0) == 1)

    // Just right
    assert(service.clamp_page_size(25) == 25)

fn test_make_profile:
    let service = UserService.builder().build()

    let user = User {
        id: UserId { value: 42 },
        name: "Bob",
        email: "bob@example.com",
        role: .Member,
    }

    let profile = service.make_profile(user, 10, 5)
    assert(profile.post_count == 10)
    assert(profile.followers == 5)
    assert(profile.user.name == "Bob")

fn test_describe_changes:
    let old = User {
        id: UserId { value: 1 },
        name: "Alice",
        email: "alice@example.com",
        role: .Member,
    }

    let new_user = User {
        id: UserId { value: 1 },
        name: "Alicia",
        email: "alice@example.com",
        role: .Member,
    }

    let desc = describe_changes(old, new_user)
    assert(desc == "name changed")

fn test_make_notification:
    let service = UserService.builder().build()

    let user = User {
        id: UserId { value: 1 },
        name: "Charlie",
        email: "charlie@example.com",
        role: .Admin,
    }

    let notif = service.make_welcome_notification(user)
    assert(notif.recipient == "charlie@example.com")
    assert(notif.subject == "Welcome to the platform")
    assert(notif.priority == .Normal)

fn test_service_config_defaults:
    let config = ServiceConfig {}
    assert(config.cache_ttl_secs == 300)
    assert(config.max_batch_size == 100)
    assert(config.notify_on_create == true)
    assert(config.notify_on_delete == false)

fn test_service_config_override:
    let config = ServiceConfig {
        cache_ttl_secs: 600,
        notify_on_delete: true,
    }
    assert(config.cache_ttl_secs == 600)
    assert(config.max_batch_size == 100)
    assert(config.notify_on_delete == true)

fn main:
    test_create_user()
    test_validation()
    test_welcome_messages()
    test_clamp_page_size()
    test_make_profile()
    test_describe_changes()
    test_make_notification()
    test_service_config_defaults()
    test_service_config_override()
    print("all tests passed")
