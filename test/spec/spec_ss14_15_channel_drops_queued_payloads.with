//! expect-stdout: ok

var CHANNEL_DROP_COUNT: i32 = 0

type ChannelDropProbe {
    value: i32,
}

impl Drop for ChannelDropProbe:
    fn drop(move self: Self):
        CHANNEL_DROP_COUNT = CHANNEL_DROP_COUNT + self.value

fn enqueue_and_drop:
    let (tx, _rx) = chan[ChannelDropProbe](2)
    tx.send(ChannelDropProbe { value: 1 })

fn main:
    enqueue_and_drop()
    assert(CHANNEL_DROP_COUNT == 1)
    print("ok")
