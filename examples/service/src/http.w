module http

use service.UserService
use domain.*

// --- HTTP Types ---
//
// Simplified HTTP types for demonstrating routing and
// request handling patterns.

pub type HttpRequest {
    method: str,
    path: str,
    body: str,
}

pub type HttpResponse {
    status: i32,
    body: str,
}

// Constructors have no receiver, so they are functions of the type (§3.1).

pub fn HttpResponse.ok(body: str) -> HttpResponse:
    HttpResponse { status: 200, body }

pub fn HttpResponse.created(body: str) -> HttpResponse:
    HttpResponse { status: 201, body }

pub fn HttpResponse.bad_request(msg: str) -> HttpResponse:
    HttpResponse { status: 400, body: msg }

pub fn HttpResponse.not_found -> HttpResponse:
    HttpResponse { status: 404, body: "not found" }

pub fn HttpResponse.no_content -> HttpResponse:
    HttpResponse { status: 204, body: "" }

pub fn HttpResponse.internal_error(msg: str) -> HttpResponse:
    HttpResponse { status: 500, body: msg }

// --- Application State ---

pub type AppState {
    service: UserService,
}

// --- Router ---
//
// Demonstrates pattern matching on (method, path) tuples
// for request routing. Handling a request mutates the state in
// place, so the handlers are `mut fn` receivers (§3.1).

extend AppState:
    pub mut fn handle_request(req: HttpRequest) -> HttpResponse:
        // The router observes the request (§3.8); the handler that keeps
        // it receives it whole.
        match (&req.method, &req.path):
            ("GET",    "/users")  => self.handle_list()
            ("POST",   "/users")  => self.handle_create(req)
            _                     => HttpResponse.not_found()

    // --- Handlers ---

    fn handle_list() -> HttpResponse:
        let size = self.service.clamp_page_size(20)
        HttpResponse.ok(f"listing users, page_size={size}")

    mut fn handle_create(req: HttpRequest) -> HttpResponse:
        var request = req
        let user_req = CreateUserRequest {
            name: move request.body,
            email: "user@example.com",
            role: .Member,
        }

        let actor = UserId { value: 0 }

        // Validate
        if let Some(err) = self.service.validate_create(user_req):
            return HttpResponse.bad_request(err)

        // Create
        let user = self.service.create_user(user_req, actor)
        HttpResponse.created(f"created user: {user.name}")
