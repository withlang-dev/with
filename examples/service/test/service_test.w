// Tests for the service example


type User {
    id: i32,
    name: str,
    email: str,
    score: i32,
}

type ServiceConfig {
    max_retries: i32,
    timeout_ms: i32,
    cache_enabled: bool,
}

enum ServiceResult { Ok | NotFound | InvalidInput | ServerError }

fn result_code(r: ServiceResult) -> i32:
    match r:
        Ok => 0
        NotFound => 1
        InvalidInput => 2
        ServerError => 3

fn make_user(id: i32, name: str, email: str, score: i32) -> User: User { id, name, email, score }

fn find_user(users: [5]User, id: i32) -> ServiceResult:
    var found = false
    for i in 0..5:
        if users[i].id == id:
            found = true
    if found then Ok else NotFound

fn get_user_score(users: [5]User, id: i32) -> i32:
    var score = 0
    for i in 0..5:
        if users[i].id == id:
            score = users[i].score
    score

type Service {
    config: ServiceConfig,
    request_count: i32,
}

extend Service:
    fn new(config: ServiceConfig) -> Service: Service { config, request_count: 0 }

    fn get_timeout(self: Service) -> i32: self.config.timeout_ms

fn validate_id(id: i32) -> ServiceResult: if id in 1..=1000 then Ok else InvalidInput

fn validate_and_find(users: [5]User, id: i32) -> ServiceResult:
    let validation = validate_id(id)
    match validation:
        Ok => find_user(users, id)
        _ => validation

fn handle_request(users: [5]User, endpoint: i32, user_id: i32) -> ServiceResult:
    match endpoint:
        1 => validate_and_find(users, user_id)
        2 => Ok
        _ => NotFound

fn identity[T](x: T) -> T: x

fn first_of[T](a: T, b: T) -> T: a

fn display_user(user: User): print(f"User #{user.id}: {user.name}")

@[test]
fn test_service_example:
    // Test ServiceResult enum
    assert(result_code(Ok) == 0)
    assert(result_code(NotFound) == 1)
    assert(result_code(InvalidInput) == 2)
    assert(result_code(ServerError) == 3)

    // Test validate_id
    assert(result_code(validate_id(1)) == 0)
    assert(result_code(validate_id(500)) == 0)
    assert(result_code(validate_id(1000)) == 0)
    assert(result_code(validate_id(0)) == 2)
    assert(result_code(validate_id(-1)) == 2)
    assert(result_code(validate_id(1001)) == 2)

    // Test make_user
    let u = make_user(1, "Alice", "alice@example.com", 95)
    assert(u.id == 1)
    assert(u.score == 95)

    // Test ServiceConfig and Service
    let config = ServiceConfig {
        max_retries: 3,
        timeout_ms: 5000,
        cache_enabled: true,
    }
    assert(config.max_retries == 3)
    assert(config.timeout_ms == 5000)
    assert(config.cache_enabled)

    let service = Service.new(config)
    assert(service.get_timeout() == 5000)
    assert(service.request_count == 0)

    // Test user repository
    let users: [5]User = [
        make_user(1, "Alice", "alice@example.com", 95),
        make_user(2, "Bob", "bob@example.com", 82),
        make_user(3, "Charlie", "charlie@example.com", 91),
        make_user(4, "Diana", "diana@example.com", 78),
        make_user(5, "Eve", "eve@example.com", 88),
    ]

    // Test find_user
    assert(result_code(find_user(users, 1)) == 0)
    assert(result_code(find_user(users, 3)) == 0)
    assert(result_code(find_user(users, 5)) == 0)
    assert(result_code(find_user(users, 99)) == 1)

    // Test get_user_score
    assert(get_user_score(users, 1) == 95)
    assert(get_user_score(users, 2) == 82)
    assert(get_user_score(users, 5) == 88)

    // Test validate_and_find
    assert(result_code(validate_and_find(users, 1)) == 0)
    assert(result_code(validate_and_find(users, 99)) == 1)
    assert(result_code(validate_and_find(users, -1)) == 2)
    assert(result_code(validate_and_find(users, 1001)) == 2)

    // Test handle_request
    assert(result_code(handle_request(users, 1, 3)) == 0)
    assert(result_code(handle_request(users, 1, 99)) == 1)
    assert(result_code(handle_request(users, 1, -1)) == 2)
    assert(result_code(handle_request(users, 2, 1)) == 0)
    assert(result_code(handle_request(users, 3, 1)) == 1)

    // Test generic functions
    assert(identity(42) == 42)
    assert(identity(true))
    assert(first_of(10, 20) == 10)
    assert(first_of(99, 1) == 99)

    // Test score computation
    var total_score = 0
    for i in 0..5:
        total_score = total_score + users[i].score
    assert(total_score == 434)
    let avg_score = total_score / 5
    assert(avg_score == 86)

    // Test display helper
    display_user(u)
