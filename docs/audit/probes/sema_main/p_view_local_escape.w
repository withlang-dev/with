fn bad() -> &i32:
  let v = 42
  &v
fn main():
  let r = bad()
  assert(*r == 42)
