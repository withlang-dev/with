//! expect-error: unreachable code

fn f():
    for x in 0..10:
        break
        print("hi")
