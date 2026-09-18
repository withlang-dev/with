type Payload {
    values: Vec[i32],
}

fn consume_first(value: Payload): value.values.len()

fn consume_second(tag: i32, value: Payload): tag + value.values.len() as i32

fn retain_as_first(source: &Vec[Payload]):
    consume_first(source.get(0))

fn retain_as_second(source: &Vec[Payload]):
    consume_second(0, source.get(0))

fn main:
    let source: Vec[Payload] = Vec.new()
    source.push(Payload { values: Vec.new() })
