//! expect-stdout: ok

enum LookupResult:
    Found(i32)
    Suspended(str)
    NotFound

error FetchError = NotFound(i32) | Timeout

fn find_user(id: i32) -> LookupResult:
    if id == 1:
        .Found(7)
    else if id == 2:
        .Suspended("policy violation")
    else:
        .NotFound

fn classify_lookup(result: LookupResult) -> i32:
    match result:
        .Found(value) => value
        .Suspended(_) => 20
        .NotFound => 30

fn fetch_data(id: i32) -> Result[i32, FetchError]:
    if id > 0:
        Ok(id)
    else:
        Err(NotFound(id))

fn classify_fetch(result: Result[i32, FetchError]) -> i32:
    match result:
        Ok(value) => value
        Err(.NotFound(id)) => id
        Err(.Timeout) => -1

fn main:
    assert(classify_lookup(find_user(3)) == 30)
    assert(classify_fetch(fetch_data(-4)) == -4)
    print("ok")
