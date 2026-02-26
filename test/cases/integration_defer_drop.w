// Integration test: defer with struct operations
type Logger = { prefix: str }

impl Logger =
    fn new(p: str) -> Logger = Logger { prefix: p }
    fn log(self: Logger, msg: str) -> void = println(msg)

fn process() -> i32 =
    let lg = Logger.new("INFO")
    defer lg.log("cleanup done")
    lg.log("processing")
    42

fn main() -> i32 =
    let result = process()
    println(result)
    0
