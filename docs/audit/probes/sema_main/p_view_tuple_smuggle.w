fn main():
  var v = 42
  let r = &v
  let t = (r, 1)
  v = 99
  let v0 = t.0
  assert(*v0 == 99)
