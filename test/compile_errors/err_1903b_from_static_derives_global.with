//! expect-error: `head` declares `from static`, but its returned view derives from `G`: `from static` states a view of static data, with no parameter or global origin (§21.1 rule 6)

// #1903 (§21.1 rule 6, spec v7.18): a view of a global is no view of static
// data: the global is written while the program runs.

var G: List[i32] = List.new()

fn head() -> &i32 from static: &G[0]

fn main:
    G.push(1)
    print(*head())
