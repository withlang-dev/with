module app.http

use app.service.UserService
use app.domain.*
use app.errors.ServiceError
use std.sync.Arc

type AppState = {
    service: Arc[UserService],
}

async fn handle_request(state: &AppState, req: HttpRequest) -> HttpResponse =
    match (req.method(), req.path_str())
        ("GET",    "/users")      -> handle_list(state, &req).await
        ("GET",    "/users/{id}") -> handle_get_profile(state, req.param("id")).await
        ("POST",   "/users")      -> handle_create(state, &req).await
        ("PUT",    "/users/{id}") -> handle_update(state, &req, req.param("id")).await
        ("DELETE", "/users/{id}") -> handle_delete(state, &req, req.param("id")).await
        _ -> HttpResponse.not_found()

async fn handle_get_profile(state: &AppState, id_str: &str) -> HttpResponse =
    let id = match id_str.parse_int()
        Ok(n)  -> UserId(n)
        Err(_) -> return HttpResponse.bad_request("invalid user id")

    match state.service.get_profile(id).await
        Ok(profile)                    -> HttpResponse.json(200, &profile)
        Err(.Db(.NotFound(..))) -> HttpResponse.not_found()
        Err(.Validation(msg))          -> HttpResponse.bad_request(&msg)
        Err(e)                         -> HttpResponse.internal_error(&e.to_string())

async fn handle_list(state: &AppState, req: &HttpRequest) -> HttpResponse =
    let page = req.query_param("page")?.parse_int().ok() ?? 1
    let per_page = req.query_param("per_page")?.parse_int().ok() ?? 20

    match state.service.list_active(page, per_page).await
        Ok(users) -> HttpResponse.json(200, &users)
        Err(e)    -> HttpResponse.internal_error(&e.to_string())

async fn handle_create(state: &AppState, req: &HttpRequest) -> HttpResponse =
    let body = match req.json[CreateUserRequest]()
        Ok(b)  -> b
        Err(_) -> return HttpResponse.bad_request("invalid request body")

    // Actor ID from auth middleware (stored in request extensions)
    let actor = req.extension[UserId]() ?? UserId(0)

    match state.service.create_user(body, actor).await
        Ok(user) -> HttpResponse.json(201, &user)
        Err(.Validation(msg)) -> HttpResponse.bad_request(&msg)
        Err(e) -> HttpResponse.internal_error(&e.to_string())

async fn handle_update(state: &AppState, req: &HttpRequest, id_str: &str) -> HttpResponse =
    let id = match id_str.parse_int()
        Ok(n)  -> UserId(n)
        Err(_) -> return HttpResponse.bad_request("invalid user id")

    let update = match req.json[UserUpdate]()
        Ok(u)  -> u
        Err(_) -> return HttpResponse.bad_request("invalid request body")

    let actor = req.extension[UserId]() ?? UserId(0)

    match state.service.update_user(id, update, actor).await
        Ok(user)                       -> HttpResponse.json(200, &user)
        Err(.Db(.NotFound(..))) -> HttpResponse.not_found()
        Err(.Validation(msg))          -> HttpResponse.bad_request(&msg)
        Err(e)                         -> HttpResponse.internal_error(&e.to_string())

async fn handle_delete(state: &AppState, req: &HttpRequest, id_str: &str) -> HttpResponse =
    let id = match id_str.parse_int()
        Ok(n)  -> UserId(n)
        Err(_) -> return HttpResponse.bad_request("invalid user id")

    let actor = req.extension[UserId]() ?? UserId(0)

    match state.service.delete_user(id, actor).await
        Ok()                         -> HttpResponse.no_content()
        Err(.Db(.NotFound(..))) -> HttpResponse.not_found()
        Err(e)                         -> HttpResponse.internal_error(&e.to_string())
