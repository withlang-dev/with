enum Small: u8:
  A
  B
  C

fn main -> i32:
  let s = sizeof[Small]()
  print(f"sizeof Small={s}")
  let t = Small.B as i32
  print(f"tag={t}")
  if s == 1: print("size-ok") else: print("size-BAD")
  if t == 1: print("tag-ok") else: print("tag-BAD")
  0
