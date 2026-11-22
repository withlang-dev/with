//! expect-stdout: ok
// #3171: 'could not read the Conan Center recipe of X' said nothing about
// which of the recipe's files was missing; the message now names it and
// its URL.
use compiler.ConanClient

fn main:
    let no_folder = conan_recipe_problem("libsodium", "cci.20220430", "", false, false)
    assert(no_folder.starts_with("could not read the Conan Center recipe of libsodium/cci.20220430: its config.yml names no folder for that version ("))
    assert(no_folder.contains("/libsodium/config.yml"))
    let no_data = conan_recipe_problem("abseil", "20250814.0", "all", false, true)
    assert(no_data.contains("conandata.yml did not fetch (") and no_data.contains("/abseil/all/conandata.yml"))
    let no_recipe = conan_recipe_problem("abseil", "20250814.0", "all", true, false)
    assert(no_recipe.contains("conanfile.py did not fetch (") and no_recipe.contains("/abseil/all/conanfile.py"))
    print("ok")
