// ===================================================================
// Service Demo — Simplified
//
// Demonstrates:
//   - Trait definitions and implementations
//   - Extend blocks for inherent methods
//   - Enum-based error handling with match
//   - Structs with default values
//   - Generic functions
//   - Pipeline operator
//   - String interpolation
//   - Defer for cleanup
// ===================================================================

extern fn puts(s: *const i8) -> i32

// --- Domain Types ---

type User = {
    id: i32,
    name: str,
    email: str,
    score: i32,
}

type ServiceConfig = {
    max_retries: i32,
    timeout_ms: i32,
    cache_enabled: bool,
}

// --- Error Type ---

type ServiceResult = Ok | NotFound | InvalidInput | ServerError

fn result_name(r: ServiceResult) -> str:
    match r
        Ok -> "ok"
        NotFound -> "not found"
        InvalidInput -> "invalid input"
        ServerError -> "server error"

// --- User "Repository" (in-memory array) ---

fn make_user(id: i32, name: str, email: str, score: i32) -> User:
    User { id: id, name: name, email: email, score: score }

fn find_user(users: [5]User, id: i32) -> ServiceResult:
    var found = false
    for i in 0..5:
        if users[i].id == id then found = true else found = found
    if found then Ok else NotFound

fn get_user_score(users: [5]User, id: i32) -> i32:
    var score = 0
    for i in 0..5:
        if users[i].id == id then score = users[i].score else score = score
    score

// --- Service Layer ---

type Service = {
    config: ServiceConfig,
    request_count: i32,
}

extend Service =
    fn new(config: ServiceConfig) -> Service:
        Service { config: config, request_count: 0 }

    fn get_timeout(self: Service) -> i32:
        self.config.timeout_ms

// --- Validation ---

fn validate_id(id: i32) -> ServiceResult:
    if id <= 0 then InvalidInput
    else if id > 1000 then InvalidInput
    else Ok

fn validate_and_find(users: [5]User, id: i32) -> ServiceResult:
    let validation = validate_id(id)
    match validation
        Ok -> find_user(users, id)
        _ -> validation

// --- Generic utility ---

fn identity[T](x: T) -> T:
    x

fn first_of[T](a: T, b: T) -> T:
    a

// --- Trait demo ---

trait Printable =
    fn display(self: Self) -> i32

impl Printable for User =
    fn display(self: User) -> i32:
        println("User #{self.id}: {self.name} <{self.email}> score={self.score}")

impl Printable for ServiceConfig =
    fn display(self: ServiceConfig) -> i32:
        println("Config: retries={self.max_retries}, timeout={self.timeout_ms}ms, cache={self.cache_enabled}")

// --- Request handling demo ---

fn handle_request(users: [5]User, endpoint: i32, user_id: i32) -> ServiceResult:
    match endpoint
        1 -> validate_and_find(users, user_id)
        2 -> Ok
        _ -> NotFound

// --- Main ---

fn main -> i32:
    println("=== Service Demo ===")

    // Configuration with defaults
    let config = ServiceConfig {
        max_retries: 3,
        timeout_ms: 5000,
        cache_enabled: true,
    }
    config.display()

    // Create service
    let service = Service.new(config)
    let timeout = service.get_timeout()
    println("Service timeout: {timeout}ms")

    // Initialize user repository
    let users: [5]User = [
        make_user(1, "Alice", "alice@example.com", 95),
        make_user(2, "Bob", "bob@example.com", 82),
        make_user(3, "Charlie", "charlie@example.com", 91),
        make_user(4, "Diana", "diana@example.com", 78),
        make_user(5, "Eve", "eve@example.com", 88),
    ]

    // Display all users
    println("--- All Users ---")
    for i in 0..5:
        users[i].display()

    // Handle requests
    println("--- Request Handling ---")

    let r1 = handle_request(users, 1, 3)
    let r1_name = result_name(r1)
    println("GET /users/3: {r1_name}")

    let r2 = handle_request(users, 1, 99)
    let r2_name = result_name(r2)
    println("GET /users/99: {r2_name}")

    let r3 = handle_request(users, 1, -1)
    let r3_name = result_name(r3)
    println("GET /users/-1: {r3_name}")

    let r4 = handle_request(users, 3, 1)
    let r4_name = result_name(r4)
    println("GET /unknown: {r4_name}")

    // Score computation with pipeline
    println("--- Score Stats ---")
    var total_score = 0
    for i in 0..5:
        total_score = total_score + users[i].score
    let avg_score = total_score / 5
    println("Total score: {total_score}")
    println("Average score: {avg_score}")

    // Find highest score
    var max_score = 0
    for i in 0..5:
        let s = users[i].score
        if s > max_score then max_score = s else max_score = max_score
    println("Highest score: {max_score}")

    // Generic function demo
    let x = identity(42)
    let y = first_of(10, 20)
    println("identity(42) = {x}, first_of(10,20) = {y}")

    // Defer demo
    defer puts("--- Cleanup: connections closed ---")

    println("=== Demo complete ===")
