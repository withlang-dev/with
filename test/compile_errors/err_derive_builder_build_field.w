//! expect-error: derive Builder cannot generate a setter for field 'build'

@[derive(Builder)]
type BadBuilder { build: i32 }

fn main:
    let _ = BadBuilder.builder()
