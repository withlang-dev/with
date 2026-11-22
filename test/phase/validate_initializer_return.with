//! args: --validate-all --prelude=core
//! expect-check-stdout: validate-all: ok

fn exercise(stop: bool):
    let text = if stop:
        return
    else:
        f"owned {stop}"
    print(text)

fn main:
    exercise(false)
    exercise(true)
