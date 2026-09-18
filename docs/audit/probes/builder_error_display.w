use std.result.BuilderError

fn main:
    let err: BuilderError = .MissingField("host")
    let text = err.display()
    print(text)
