fn id(x: &i32) -> &i32:
  x
fn main():
  let v = 42
  let r = id(&v)
  assert(*r == 42)
