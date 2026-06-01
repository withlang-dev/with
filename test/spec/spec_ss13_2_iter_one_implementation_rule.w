// Spec test: Section 13.2 — Iter One-Implementation Rule (formerly 25.70)

type CountUp { current: i32, limit: i32 }

fn CountUp.new(limit: i32) -> CountUp:
    CountUp { current: 0, limit }

impl Iter[i32] for CountUp =
    fn next(mut self: Self) -> Option[i32]:
        if self.current >= self.limit:
            return .None
        let value = self.current
        self.current = self.current + 1
        .Some(value)

type WordIter { index: i32 }

impl Iter[str] for WordIter =
    fn next(mut self: Self) -> Option[str]:
        if self.index == 0:
            self.index = 1
            return .Some("alpha")
        if self.index == 1:
            self.index = 2
            return .Some("beta")
        .None

extend CountUp:
    fn words(self: &Self) -> WordIter:
        WordIter { index: 0 }

fn test_primary_iter_impl:
    let numbers = CountUp.new(4)
    var sum = 0
    for n in numbers:
        sum = sum + n
    assert(sum == 6)

fn test_named_method_for_alternate_iteration:
    let numbers = CountUp.new(0)
    var text = ""
    for word in numbers.words():
        text = text ++ word
    assert(text == "alphabeta")
