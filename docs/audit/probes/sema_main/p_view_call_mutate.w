fn id(x: &i32) -> &i32:
  x
fn main():
  var v = 42
  let r = id(&v)
  v = 99
  assert(*r == 99)
