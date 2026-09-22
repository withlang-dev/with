module main

use service.UserService
use service.ServiceConfig
use domain.*
use http.*

// --- Entry Point ---
//
// Demonstrates:
//   - Builder pattern for service configuration
//   - Request routing via pattern matching
//   - Domain types with default values
//   - f-string interpolation

fn main:
    // Configuration -- only override fields that differ from defaults
    let config = ServiceConfig {
        cache_ttl_secs: 600,
        notify_on_delete: true,
        max_batch_size: 50,
    }

    // Build the service: the setters consume and return the builder
    let service = UserService.builder().with_config(config).build()

    var state = AppState { service }

    print("=== Service Demo ===")

    // Simulate some HTTP requests
    let create_req = HttpRequest {
        method: "POST",
        path: "/users",
        body: "Alice",
    }

    let resp = state.handle_request(create_req)
    print(f"POST /users -> {resp.status}: {resp.body}")

    let list_req = HttpRequest {
        method: "GET",
        path: "/users",
        body: "",
    }

    let resp2 = state.handle_request(list_req)
    print(f"GET /users  -> {resp2.status}: {resp2.body}")

    // Try a 404
    let bad_req = HttpRequest {
        method: "DELETE",
        path: "/unknown",
        body: "",
    }

    let resp3 = state.handle_request(bad_req)
    print(f"DELETE /unknown -> {resp3.status}: {resp3.body}")

    print("=== Done ===")
