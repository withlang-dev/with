//! expect-stdout: ok

type Detail { name: str }

type Response {
    body: str,
    cached: Result[str, str],
    detail: Detail,
    maybe_detail: Option[Detail],
}

fn Response.body_len(self: &Self) -> usize:
    self.body.len()

fn Response.try_body(self: &Self) -> Result[str, str]:
    Ok(self.body)

fn Response.add_to_len(self: &Self, n: usize) -> usize:
    self.body.len() + n

fn explode -> usize:
    assert(false)
    0

fn good_response -> Result[Response, str]:
    Ok(Response {
        body: "payload",
        cached: Ok("cached"),
        detail: Detail { name: "detail" },
        maybe_detail: Some(Detail { name: "maybe" }),
    })

fn bad_response -> Result[Response, str]:
    Err("api down")

fn main:
    let body: Result[str, str] = good_response()?.body
    assert(body.unwrap() == "payload")

    let passed_err: Result[str, str] = bad_response()?.body
    match passed_err:
        Err(msg) => assert(msg == "api down")
        _ => assert(false)

    let cached: Result[str, str] = good_response()?.cached
    assert(cached.unwrap() == "cached")

    let len: Result[usize, str] = good_response()?.body_len()
    assert(len.unwrap() == 7)

    let tried: Result[str, str] = good_response()?.try_body()
    assert(tried.unwrap() == "payload")

    let lazy: Result[usize, str] = bad_response()?.add_to_len(explode())
    match lazy:
        Err(msg) => assert(msg == "api down")
        _ => assert(false)

    let nested_name: Result[str, str] = good_response()?.detail?.name
    assert(nested_name.unwrap() == "detail")

    let maybe_wrapped: Result[Option[Detail], str] = good_response()?.maybe_detail
    match maybe_wrapped:
        Ok(Some(detail)) => assert(detail.name == "maybe")
        _ => assert(false)

    print("ok")
