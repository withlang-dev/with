trait BoxDynLogger:
    fn message(self: &Self) -> str

type BoxDynConsole {
    level: i32,
}

impl BoxDynLogger for BoxDynConsole:
    fn message(self: &Self) -> str:
        if self.level == 7:
            return "ready"
        "wrong"

fn test_box_to_dyn_trait_dispatch:
    let logger: Box[dyn BoxDynLogger] = Box.new(BoxDynConsole { level: 7 })
    assert(logger.message() == "ready")
