// #1903: a private global reached only through a returned view.
var HIDDEN: List[i32] = List.new()

pub fn seed(v: i32): HIDDEN.push(v)

pub fn grow():
    for i in 0..1000: HIDDEN.push(i)

pub fn first(p: &List[i32]) -> &i32: &HIDDEN[0]
