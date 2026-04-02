// Channel types for fiber-safe communication.
//
// Channels pass values between fibers using sized element slots.
// Send copies elem_size bytes into the channel's internal buffer.
// Recv copies elem_size bytes out. Both may suspend the fiber.
//
// Usage:
//   use std.channel
//   let ch = Channel[i32].new(8)  // bounded channel, capacity 8
//   let tx = ch.sender()
//   let rx = ch.receiver()

extern fn with_channel_create(capacity: i32, elem_size: i32) -> i64
extern fn with_channel_send(ch: i64, value_ptr: *u8) -> void
extern fn with_channel_recv(ch: i64, out_ptr: *mut u8) -> i32
extern fn with_channel_close(ch: i64) -> void
extern fn with_channel_destroy(ch: i64) -> void

pub type Channel[T] { handle: i64 }
pub type Sender[T] { handle: i64 }
pub type Receiver[T] { handle: i64 }
