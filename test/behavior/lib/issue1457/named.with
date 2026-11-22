// #1457: a trait both issue1457.ta's and issue1457.tb's `Item` implement.
pub trait Named:
    fn name(self: &Self) -> str
    fn shout(self: &Self) -> str: self.name() ++ "!"
