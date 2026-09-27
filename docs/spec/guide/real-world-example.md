# 14.21 Real-World Example

```
async fn main:
    let listener = net.listen("0.0.0.0:8080").await
    print("Listening on :8080")

    loop:
        let conn = listener.accept().await
        handle_connection(conn)

async fn handle_connection(conn: TcpStream):
    let req = http.parse_request(&conn).await

    let response = match req.path_str():
        "/users" =>
            let users = db.query("SELECT * FROM users").await
            http.json_response(200, users)
        "/health" =>
            http.text_response(200, "ok")
        _ =>
            http.text_response(404, "not found")

    conn.write_all(response.as_bytes()).await
```

Reads like synchronous code. Each connection is a fiber. Thousands
concurrent. No callbacks, no state machines, no type gymnastics.
