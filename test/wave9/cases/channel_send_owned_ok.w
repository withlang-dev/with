fn main -> i32:
    let ch = Channel(2)
    send(ch, 123)
    let v = recv(ch)
    if v == 123 then 0 else 1
