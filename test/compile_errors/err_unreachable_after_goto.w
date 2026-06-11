//! expect-error: unreachable code

fn main:
    goto 'done
    print("never")
    'done:
        print("done")
