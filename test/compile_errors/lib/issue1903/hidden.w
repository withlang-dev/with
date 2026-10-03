// #1903: a private global reached only through a returned view.
var HIDDEN: Vec[i32] = Vec.new()

pub fn seed(v: i32): HIDDEN.push(v)

pub fn grow():
    for i in 0..1000: HIDDEN.push(i)

pub fn first(p: &Vec[i32]) -> &i32: &HIDDEN[0]
