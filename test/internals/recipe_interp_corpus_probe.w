use compiler.RecipeInterp
use std.fs
use std.process

fn show(c: &RecipeComponent):
    print(f"  [{c.name}] libs={c.libs.join(\",\")} sys={c.system_libs.join(\",\")} fw={c.frameworks.join(\",\")} libdirs={c.libdirs.join(\",\")} req={c.requires.join(\",\")} defs={c.defines.join(\",\")} exe={c.exelinkflags.join(\",\")}")

fn main:
    let argv = args()
    let os = argv[1].clone()
    for i in 2..argv.len() as i32:
        let recipe = read_file(argv[i]) ?? ""
        let env = RecipeEnv { os: os.clone(), arch: "x86_64", compiler: if os == "Macos": "apple-clang" else: if os == "Linux": "gcc" else: "clang", compiler_version: "13", build_type: "Release", version: "3.4", package_folder: "", options: Vec.new(), options_known: false }
        let info = recipe_package_info(recipe, &env)
        print(f"== {argv[i]} ok={info.ok} {info.problem}")
        show(&info.root)
        for c in info.components: show(c)
        for n in info.notes: print("  note: " ++ n)
