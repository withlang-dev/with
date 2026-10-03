//! expect-stdout: 42
//! expect-stdout: 30

// §2.4 IndexPlace for arrays — place projection via PK_INDEX.

type Point { x: i32, y: i32 }

fn main:
    // Direct index assignment on array
    var arr = [10, 20, 30]
    arr[1] = 42
    print(int_to_string(arr[1] as i64))

    // Compound assignment on array
    arr[2] += 0
    print(int_to_string(arr[2] as i64))
