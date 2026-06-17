//! expect-stdout: ok

type Message {
    id: i32,
    text: str,
}

fn main:
    let (str_tx, str_rx) = chan[str](2)
    str_tx.send("hello")
    let s = str_rx.recv()
    assert(s == "hello")

    let (msg_tx, msg_rx) = chan[Message](1)
    msg_tx.send(Message { id: 7, text: "seven" })
    let msg = msg_rx.recv()
    assert(msg.id == 7)
    assert(msg.text == "seven")

    let (vec_tx, vec_rx) = chan[Vec[i32]](1)
    let values: Vec[i32] = Vec.new()
    values.push(3)
    values.push(5)
    vec_tx.send(values)
    let received = vec_rx.recv()
    assert(received.len() == 2)
    assert(received.get(0) == 3)
    assert(received.get(1) == 5)

    print("ok")
