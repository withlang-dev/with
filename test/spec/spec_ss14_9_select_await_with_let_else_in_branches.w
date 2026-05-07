//! skip: non-executable spec sketch for Section 14.9 — Select Await with Let-Else in Branches (formerly 25.56); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.9 — Select Await with Let-Else in Branches (formerly 25.56)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: let...else: inside branch body
async fn test(rx: Receiver[i32]):
    var items = Vec.new()
    loop:
        select await
            opt = rx.recv() =>
                let Some(item) = opt else: break
                items.push(item)
            _ = timeout(1.secs()) => break

// PASS: multiple branches with let...else
async fn serve(listener: TcpListener, ctrl: Receiver[str]):
    loop:
        select await
            result = listener.accept() =>
                let Ok(conn) = result else: continue
                handle(conn)
            opt = ctrl.recv() =>
                let Some(msg) = opt else: break
                process(msg)
