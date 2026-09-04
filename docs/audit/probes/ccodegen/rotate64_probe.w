fn main -> i32:
  let v = 1 as i64
  let r = v.rotate_left(1)
  print(f"rot={r}")
  if r == 2: print("rot-ok") else: print("rot-BAD")
  let s = (256 as i64).swap_bytes()
  print(f"swap={s}")
  0
