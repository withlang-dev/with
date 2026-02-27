use std.process

@[test]
fn test_hello:
    let output = pipe_read("./zig-out/bin/with run src/hello_world.w")
    assert_eq_str(output, "Hello, World!\n")
