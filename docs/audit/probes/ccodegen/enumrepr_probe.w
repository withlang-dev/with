enum Small: u8:
  A
  B
  C

enum Big: i64:
  Neg = -5
  Huge = 7000000000

fn main -> i32:
  let s = sizeof[Small]()
  let b = sizeof[Big]()
  print(f"sizeof Small={s} sizeof Big={b}")
  let h = Big.Huge as i64
  print(f"huge={h}")
  if h == 7000000000: print("huge-ok") else: print("huge-BAD")
  let t = Small.B as i32
  print(f"tag={t}")
  0
