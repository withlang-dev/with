// Test enum with display-like methods
type Season = Spring | Summer | Autumn | Winter

extend Season =
    fn name(self: Season) -> str:
        match self
            Spring -> "Spring"
            Summer -> "Summer"
            Autumn -> "Autumn"
            Winter -> "Winter"

    fn is_cold(self: Season) -> bool:
        match self
            Winter -> true
            Autumn -> true
            _ -> false

fn main -> i32:
    let s = Winter
    println(s.name())
    println(s.is_cold())
    let s2 = Summer
    println(s2.name())
    println(s2.is_cold())
