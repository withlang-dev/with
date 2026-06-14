//! expect-error: unknown method 'missing' for optional-chain payload type 'Response'

type Response { body: str }

fn main:
    let response: Result[Response, str] = Ok(Response { body: "payload" })
    let _body = response?.missing()
