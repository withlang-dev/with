module main

use service.UserService
use service.ServiceConfig
use domain.*
use http.*

// The builder pattern for the configuration, request routing by pattern
// matching, domain types with default values, f-strings.

fn main:
    // Only the fields that differ from the defaults
    let config = ServiceConfig { cache_ttl_secs: 600, notify_on_delete: true, max_batch_size: 50 }
    // The setters consume and return the builder
    let service = UserService.builder().with_config(config).build()
    var state = AppState { service }

    print("=== Service Demo ===")
    let requests = [HttpRequest { method: "POST", path: "/users", body: "Alice" }, HttpRequest { method: "GET", path: "/users", body: "" }, HttpRequest { method: "DELETE", path: "/unknown", body: "" }]
    for req in requests:
        let route = f"{req.method} {req.path}"
        let resp = state.handle_request(req)
        print(f"{route} -> {resp.status}: {resp.body}")
    print("=== Done ===")
