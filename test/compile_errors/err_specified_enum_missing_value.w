//! expect-error: @[specified] requires explicit discriminant value

@[specified]
enum MessageType: u16:
    Ping = 1
    Pong

fn main:
    let _ = MessageType.Pong
