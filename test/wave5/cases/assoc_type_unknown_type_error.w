trait Provider =
    type Item
    fn get(self: &Self) -> Item

type Local = { v: i32 }

impl Provider for Local
    type Item = i32
    fn get(self: &Local) -> Item:
        self.v

fn main -> i32:
    0
