fn grade(score: i32) -> str:
    match score
        90..100 -> "A"
        80..89 -> "B"
        70..79 -> "C"
        _ -> "F"

fn main -> i32:
    println(grade(95))
    println(grade(85))
    println(grade(75))
    println(grade(50))
