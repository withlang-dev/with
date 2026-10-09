//! expect-stdout: ok

type Message {
    id: i32,
    text: str,
}

fn main:
    let (str_tx, str_rx) = chan[str](2)
    str_tx.send("hello")
    let s = str_rx.recv().unwrap()
    assert(s == "hello")

    let (msg_tx, msg_rx) = chan[Message](1)
    msg_tx.send(Message { id: 7, text: "seven" })
    let msg = msg_rx.recv().unwrap()
    assert(msg.id == 7)
    assert(msg.text == "seven")

    let (list_tx, list_rx) = chan[List[i32]](1)
    let values: List[i32] = List.new()
    values.push(3)
    values.push(5)
    list_tx.send(values)
    let received = list_rx.recv().unwrap()
    assert(received.len() == 2)
    assert(received[0] == 3)
    assert(received[1] == 5)

    print("ok")
