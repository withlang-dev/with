//! expect-stdout: ok
// #970: an install destination under `$HOME/`, `$INSTALL_BINDIR/` or
// `$INSTALL_LIBDIR/` whose variable is empty is refused before expansion,
// which fell back to a project path: with HOME unset `$HOME/x` was
// installed into ./$HOME/x and the build went green.
use BuildGraphSupport
use std.process

fn main:
    assert(set_env("HOME", "") == 0)
    assert(set_env("USERPROFILE", "") == 0)
    assert(build_graph_install_prefix_unset("$HOME/bin/tool") == "$HOME")
    assert(build_graph_install_prefix_unset("dist/tool") == "")
    assert(set_env("HOME", "/home/someone") == 0)
    assert(build_graph_install_prefix_unset("$HOME/bin/tool") == "")
    print("ok")
