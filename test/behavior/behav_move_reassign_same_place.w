type Options {
    name: str,
    values: List[i32],
}

fn normalize(options: Options) -> Options:
    var out = options
    out

fn normalize_values(values: List[i32]) -> List[i32]:
    var out = values
    out

fn main:
    var options = Options { name: "kept", values: List.new() }
    options.values.push(1)
    options = normalize(move options)
    if options.name != "kept":
        return 1
    if options.values.len() != 1:
        return 2
    options = move options
    if options.name != "kept":
        return 3
    if options.values.len() != 1:
        return 4
    for _i in 0..1:
        options = normalize(move options)
    if options.name != "kept":
        return 5
    if options.values.len() != 1:
        return 6
    options.values = normalize_values(move options.values)
    if options.values.len() != 1:
        return 7
    0
