// Test nested enum matching
type Inner = A(i32) | B

type Outer = X(Inner) | Y

fn process(o: Outer) -> i32:
    match o
        X(inner) -> match inner
            A(n) -> n
            B -> 0
        Y -> -1

fn main -> i32:
    println(process(X(A(42))))
    println(process(X(B)))
    println(process(Y))
