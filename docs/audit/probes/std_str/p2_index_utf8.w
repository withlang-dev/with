fn main:
    let s = "abc"
    // T23: out-of-range byte_at — loud panic or silent?
    print(f"inrange={s.byte_at(0)}")
    print(f"oor_high={s.byte_at(3)}")
    print(f"oor_neg={s.byte_at(-1)}")
    print(f"oor_big={s.byte_at(1000000)}")
    // T23: slice clamping — loud or silent?
    print(f"slice_oor=[{s.slice(-5, 100)}]")
    print(f"slice_empty=[{s.slice(2, 2)}]")
    print(f"slice_inv=[{s.slice(2, 1)}]")
    print(f"slice_full=[{s.slice(0, 3)}]")
    // T23: invalid UTF-8 bytes pass through silently?
    let bad = "\xff\xfe"
    print(f"badlen={bad.len()} b0={bad.byte_at(0)} b1={bad.byte_at(1)}")
    let part = "héllo".slice(0, 2)
    print(f"midcut_len={part.len()} midcut_b1={part.byte_at(1)}")
    // T23: repeat/replace edge silence
    print(f"rep0=[{"ab".repeat(0)}] repneg=[{"ab".repeat(-3)}]")
    print("t23-done")
