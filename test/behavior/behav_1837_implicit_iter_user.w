//! expect-stdout: 10 20 30
//! expect-stdout: 20 40 60
//! expect-stdout: 11 21 31
//! expect-stdout: 3

// §13.5 (#1837): a user type with no `next()` and a non-generic `fn iter()`
// returning its own Iter[T] iterates bare, as if `.iter()` were spelled —
// through an owned binding and through a `&Deck` view.
type Deck { cards: List[i32] }

type DeckIter = ephemeral { cards: &List[i32], i: i32 }

impl DeckIter:
    mut fn next() -> Option[i32]:
        if self.i >= self.cards.len32():
            return None
        let v = self.cards[self.i]
        self.i += 1
        Some(v)

impl Deck:
    fn iter() -> DeckIter: DeckIter { cards: &self.cards, i: 0 }
    fn len(): self.cards.len32()

fn doubled(d: &Deck) -> str:
    var out = ""
    for c in d:
        out = if out.len() == 0: f"{c * 2}" else: out ++ f" {c * 2}"
    out

fn main:
    var cards: List[i32] = List.new()
    cards.push(10)
    cards.push(20)
    cards.push(30)
    let deck = Deck { cards: cards }
    var out = ""
    for c in deck:
        out = if out.len() == 0: f"{c}" else: out ++ f" {c}"
    print(out)
    print(doubled(&deck))
    // §13.6: a comprehension clause is the same iteration.
    let bumped: List[i32] = [c + 1 for c in deck]
    print(f"{bumped[0]} {bumped[1]} {bumped[2]}")
    print(f"{deck.len()}")
