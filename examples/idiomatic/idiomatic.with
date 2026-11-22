// Idiomatic With — concise error handling, pattern matching, pipelines, async.

type User { id: i32, name: str, active: bool }

enum LookupResult:
    Found(User)
    | Suspended(str)
    | NotFound

fn find_user(id: i32) -> LookupResult:
    match id:
        1 => .Found(User { id: 1, name: "Alice", active: true })
        2 => .Suspended("policy violation")
        _ => .NotFound

fn format_user(user: User): f"{user.name} (#{user.id})"

fn get_dashboard(user_id: i32):
    match find_user(user_id):
        .Found(user) => f"Dashboard for {user |> format_user}"
        .Suspended(reason) => f"Account suspended: {reason}"
        .NotFound => "User not found"

// --- Pipeline composition ---

fn double(x: i32): x * 2
fn add_one(x: i32): x + 1
fn to_str(x: i32): f"{x}"

fn pipeline_demo:
    let result = 5 |> double |> add_one |> to_str
    print(f"pipeline: {result}")
    assert(result == "11")

// --- Error handling with Result ---

error FetchError = NotFound(i32) | Timeout

fn fetch_data(id: i32) -> Result[str, FetchError]:
    if id > 0: Ok(f"data-{id}") else: Err(.NotFound(id))

fn process_with_errors:
    match fetch_data(1):
        Ok(data) => print(f"got: {data}")
        Err(e) => print(f"error: {e}")
    match fetch_data(-1):
        Ok(data) => print(f"unexpected: {data}")
        Err(.NotFound(id)) => print(f"not found: {id}")
        Err(.Timeout) => print("timeout")

print("=== Idiomatic With Demo ===\n")
for id in 1..=3: print(get_dashboard(id))
print("")
pipeline_demo()
print("")
process_with_errors()
print("\n=== Done ===")
