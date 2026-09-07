enum E:
  A
  B(i32)

fn main -> i32:
  print(f"sizeof E={sizeof[E]()}")
  let x = E.B(42)
  print(f"x={x}")
  0
