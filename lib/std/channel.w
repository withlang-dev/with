// Channel types for fiber-safe communication.
//
// Usage:
//   use std.channel
//   let (tx, rx) = chan[i32](8)   // bounded channel, capacity 8
//   tx.send(42)
//   let val = rx.recv()          // Option[T]: None once closed and drained
//
// A send to a full channel and a recv from an empty open one wait for another
// task. With no task left that could make that progress, the wait would
// never end: the program stops with a deadlock panic (#1000).
//
// chan[T](capacity) is a compiler builtin that returns (Sender[T], Receiver[T]).
// Sender and Receiver enforce directionality at compile time.

use rt.channel_runtime

// chan[T](capacity) is a compiler builtin — defined in CodegenDispatch.w.
// It returns (Sender[T], Receiver[T]).

pub type Sender[T] { handle: i64 }
pub type Receiver[T] { handle: i64 }

// §14.15: Sender[T] is Clone and never Copy. A shared producer is spelled
// `tx.clone()`; every clone holds the channel open, and the channel closes
// when the last sender drops. Sender[T]: Send only when T: Send.
impl[T] Clone for Sender[T]:
    fn clone() -> Self:
        with_channel_retain_sender(self.handle)
        Sender { handle: self.handle }

impl[T] Drop for Sender[T]:
    move fn drop():
        with_channel_release_sender(self.handle)

impl[T] Drop for Receiver[T]:
    move fn drop():
        with_channel_release_receiver(self.handle)
