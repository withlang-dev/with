enum Pick[T]:
    One(T)
    Two(T)

pub type Holder[T] { pick: Pick[T] }

pub fn Holder.first[T](v: T) -> Holder[T]: Holder { pick: .One(v) }

impl[T] Holder[T]:
    pub fn is_one() -> bool:
        match self.pick:
            .One(_) => true
            .Two(_) => false
