//! expect-stdout: ok

fn default_file(file: str = __FILE__) -> str:
    file

fn default_line(line: u32 = __LINE__) -> u32:
    line

fn default_fn(name: str = __FN__) -> str:
    name

fn direct_fn -> str:
    __FN__

comptime fn ct_default_src(loc: str = src()) -> str:
    loc

comptime fn ct_default_fn(name: str = __FN__) -> str:
    name

comptime fn ct_call_default_src -> str:
    ct_default_src()

comptime fn ct_call_default_fn -> str:
    ct_default_fn()

const CONST_FILE: str = comptime __FILE__
const CONST_LINE: u32 = comptime __LINE__
const CT_DEFAULT_SRC: str = comptime ct_call_default_src()
const CT_DEFAULT_FN: str = comptime ct_call_default_fn()

fn main:
    assert(__FILE__.contains("behav_magic_const.w"))
    assert(CONST_FILE.contains("behav_magic_const.w"))
    assert(CT_DEFAULT_SRC.contains("behav_magic_const.w"))
    assert(__LINE__ > 0)
    assert(CONST_LINE > 0)
    assert(direct_fn() == "direct_fn")
    assert(CT_DEFAULT_FN == "ct_call_default_fn")

    assert(default_file().contains("behav_magic_const.w"))
    let expected_line = __LINE__ + 1
    assert(default_line() == expected_line)
    assert(default_fn() == "main")
    print("ok")
