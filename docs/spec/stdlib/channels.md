# 14.15 Channels

```
let (tx, rx) = chan[Message](buffer: 10)

tx.send(msg).await                // suspends fiber if full
let msg = rx.recv().await         // Option[Message]: suspends fiber if
                                  // empty; None once closed AND drained

// The blessed worker loop — receives until the sender hangs up,
// then falls out with zero ceremony:
for msg in rx:
    handle(msg)

// Non-blocking:
match rx.try_recv():
    Some(msg) => handle(msg)
    None      => ()
```

`recv()` returns `Option[T]` (D10): buffered messages are always
delivered first, and `None` means the channel is closed and drained —
termination is in the type, never a sentinel value or a panic. In a
fallible context the happy path stays bare: `rx.recv()?`.

Channels transfer ownership: sending moves the value. **Channel
element types must be `Send`, not merely `ScopedSend`.** This is
critical: a channel decouples the lifetime of data from the sender's
stack frame. Even inside an `async scope`, Fiber 1 can send a
reference to its own local and then drop that local before Fiber 2
reads the message. `ScopedSend` guarantees the *scope* outlives the
fibers, but not that Fiber 1's locals outlive Fiber 2's reads.

`Sender[T]` is `Clone` and never `Copy`: a shared producer is spelled
`tx.clone()`, and every clone holds the channel open. The channel closes
when the last sender drops, not the first. `Sender[T]` is `Send` only when
`T` is `Send`, so a cloned sender cannot carry a non-`Send` payload across
fibers.

```
// ERROR: ephemeral values cannot be sent over channels
async scope s =>
    let (tx, rx) = chan[&str](10)
    s.track(async:
        let local = "hello".to_owned()
        tx.send(local.as_view()).await  // ERROR: &str is not Send
    )
    s.track(async:
        let msg = rx.recv().await       // would be use-after-free
    )

// OK: send owned values over channels
let (tx, rx) = chan[String](10)
tx.send("hello").await                  // str literal, String is Send
```
