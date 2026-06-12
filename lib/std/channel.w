// Channel types for fiber-safe communication.
//
// Usage:
//   use std.channel
//   let (tx, rx) = chan[i32](8)   // bounded channel, capacity 8
//   tx.send(42)
//   let val = rx.recv()
//
// chan[T](capacity) is a compiler builtin that returns (Sender[T], Receiver[T]).
// Sender and Receiver enforce directionality at compile time.

extern fn with_channel_create(capacity: i32, elem_size: i32) -> i64
extern fn with_channel_send(ch: i64, value_ptr: *u8) -> Unit
extern fn with_channel_recv(ch: i64, out_ptr: *mut u8) -> i32
extern fn with_channel_close(ch: i64) -> Unit
extern fn with_channel_destroy(ch: i64) -> Unit

// chan[T](capacity) is a compiler builtin — defined in CodegenDispatch.w.
// It returns (Sender[T], Receiver[T]).

pub type Sender[T] { handle: i64 }
pub type Receiver[T] { handle: i64 }
