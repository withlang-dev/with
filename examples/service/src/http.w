module http

use service.UserService
use domain.*

// --- HTTP Types ---
//
// Simplified HTTP types for demonstrating routing and
// request handling patterns.

type HttpRequest {
    method: str,
    path: str,
    body: str,
}

type HttpResponse {
    status: i32,
    body: str,
}

extend HttpResponse:
    fn ok(body: str) -> HttpResponse:
        HttpResponse { status: 200, body }

    fn created(body: str) -> HttpResponse:
        HttpResponse { status: 201, body }

    fn bad_request(msg: str) -> HttpResponse:
        HttpResponse { status: 400, body: msg }

    fn not_found -> HttpResponse:
        HttpResponse { status: 404, body: "not found" }

    fn no_content -> HttpResponse:
        HttpResponse { status: 204, body: "" }

    fn internal_error(msg: str) -> HttpResponse:
        HttpResponse { status: 500, body: msg }

// --- Application State ---

type AppState {
    service: UserService,
}

// --- Router ---
//
// Demonstrates pattern matching on (method, path) tuples
// for request routing.

fn handle_request(state: &mut AppState, req: HttpRequest) -> HttpResponse:
    match (req.method, req.path):
        ("GET",    "/users")  => handle_list(state)
        ("POST",   "/users")  => handle_create(state, req)
        _                     => HttpResponse.not_found()

// --- Handlers ---

fn handle_list(state: &AppState) -> HttpResponse:
    let size = state.service.clamp_page_size(20)
    HttpResponse.ok(f"listing users, page_size={size}")

fn handle_create(state: &mut AppState, req: HttpRequest) -> HttpResponse:
    let user_req = CreateUserRequest {
        name: req.body,
        email: "user@example.com",
        role: .Member,
    }

    let actor = UserId { value: 0 }

    // Validate
    match state.service.validate_create(user_req):
        Some(err) => return HttpResponse.bad_request(err)
        None => ()

    // Create
    let user = state.service.create_user(user_req, actor)
    HttpResponse.created(f"created user: {user.name}")
