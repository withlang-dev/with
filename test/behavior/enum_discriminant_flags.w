//! expect-stdout: 012124

enum NotFlags: i32 { A | B | C }

@[flags]
enum Flags: i32 { X | Y | Z }

fn main:
    // Without flags: 0, 1, 2
    write(int_to_string(NotFlags.A))
    write(int_to_string(NotFlags.B))
    write(int_to_string(NotFlags.C))
    // With flags: should be 1, 2, 4
    write(int_to_string(Flags.X))
    write(int_to_string(Flags.Y))
    write(int_to_string(Flags.Z))
