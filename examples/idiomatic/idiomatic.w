// Idiomatic With — demonstrates concise error handling,
// pattern matching, pipeline operators, and async.

type User { id: i32, name: str, active: bool }

enum LookupResult {
    Found(User)
    | Suspended(str)
    | NotFound
}

fn find_user(id: i32) -> LookupResult:
    if id == 1:
        .Found(User { id: 1, name: "Alice", active: true })
    else if id == 2:
        .Suspended("policy violation")
    else:
        .NotFound

fn format_user(user: User) -> str:
    "{user.name} (#{user.id})"

fn get_dashboard(user_id: i32) -> str:
    match find_user(user_id):
        .Found(user) =>
            let display = user |> format_user
            "Dashboard for {display}"

        .Suspended(reason) =>
            "Account suspended: {reason}"

        .NotFound =>
            "User not found"

// --- Pipeline composition ---

fn double(x: i32) -> i32: x * 2
fn add_one(x: i32) -> i32: x + 1
fn to_str(x: i32) -> str: "{x}"

fn pipeline_demo:
    let result = 5 |> double |> add_one |> to_str
    print("pipeline: {result}")
    assert(result == "11")

// --- Error handling with Result ---

error FetchError = NotFound(i32) | Timeout

fn fetch_data(id: i32) -> Result[str, FetchError]:
    if id > 0:
        Ok("data-{id}")
    else:
        Err(.NotFound(id))

fn process_with_errors:
    match fetch_data(1):
        Ok(data) => print("got: {data}")
        Err(e) => print("error: {e}")

    match fetch_data(-1):
        Ok(data) => print("unexpected: {data}")
        Err(.NotFound(id)) => print("not found: {id}")
        Err(.Timeout) => print("timeout")

// --- Main ---

fn main:
    print("=== Idiomatic With Demo ===\n")

    print(get_dashboard(1))
    print(get_dashboard(2))
    print(get_dashboard(3))

    print("")
    pipeline_demo()

    print("")
    process_with_errors()

    print("\n=== Done ===")
