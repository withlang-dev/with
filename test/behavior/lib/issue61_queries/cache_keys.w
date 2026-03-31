pub type Tape {
    chunks: Vec[i32],
    label: str,
}

pub type MeterBox {
    width: i32,
    height: i32,
}

pub fn Tape.len(self: Tape) -> i32:
    self.chunks.len() as i32 + self.label.len() as i32

pub fn Tape.head(self: Tape) -> i32:
    self.chunks[0]

pub fn MeterBox.len(self: MeterBox) -> i32:
    self.width + self.height

pub fn MeterBox.head(self: MeterBox) -> i32:
    self.width

pub fn build_tape() -> Tape:
    let chunks: Vec[i32] = Vec.new()
    chunks.push(9)
    chunks.push(11)
    Tape {
        chunks,
        label: "xy",
    }

pub fn build_meter_box() -> MeterBox:
    MeterBox {
        width: 3,
        height: 4,
    }

pub fn cache_key_score() -> i32:
    let tape = build_tape()
    let meter = build_meter_box()
    tape.len() + tape.head() + meter.len() + meter.head()
