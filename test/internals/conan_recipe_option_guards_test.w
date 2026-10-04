//! expect-stdout: ok

use compiler.ConanClient

// #2084: SDL 3's package_info, in the recipe's own shapes: every Apple
// framework sits behind an option (`self.options.get_safe("audio")`), the
// whole block behind `is_apple_os(self) and not self.options.shared`, one
// framework is linked weakly through exelinkflags, and the Windows system
// libraries are a list written over several lines. The reader skipped all of
// it, so a static SDL linked with no frameworks at all.
fn sdl_fixture() -> str:
    "class SDLConan:\n" ++
    "    def package_info(self):\n" ++
    "        sdl_lib_name = \"SDL3\"\n" ++
    "        if (is_msvc(self) or self._is_clang_cl) and not self.options.shared:\n" ++
    "            sdl_lib_name = f\"{sdl_lib_name}-static\"\n" ++
    "        if self.settings.os in (\"Linux\", \"FreeBSD\", \"Macos\"):\n" ++
    "            self.cpp_info.components[\"sdl3\"].system_libs.append(\"pthread\")\n" ++
    "        if is_apple_os(self) and not self.options.shared:\n" ++
    "            self.cpp_info.components[\"sdl3\"].frameworks = [\"CoreVideo\", \"Foundation\"]\n" ++
    "            if self.settings.os == \"Macos\":\n" ++
    "                self.cpp_info.components[\"sdl3\"].frameworks.extend([\"Cocoa\", \"Carbon\"])\n" ++
    "            if self.options.get_safe(\"audio\"):\n" ++
    "                self.cpp_info.components[\"sdl3\"].frameworks.extend([\"CoreAudio\", \"AudioToolbox\", \"AVFoundation\"])\n" ++
    "            if self.options.get_safe(\"video\"):\n" ++
    "                if self.settings.os in (\"iOS\", \"tvOS\", \"visionOS\", \"watchOS\"):\n" ++
    "                    self.cpp_info.components[\"sdl3\"].frameworks.extend([\"CoreGraphics\", \"QuartzCore\", \"UIKit\"])\n" ++
    "                else:\n" ++
    "                    self.cpp_info.components[\"sdl3\"].frameworks.append(\"UniformTypeIdentifiers\")\n" ++
    "            if self.options.get_safe(\"joystick\"):\n" ++
    "                self.cpp_info.components[\"sdl3\"].frameworks.append(\"GameController\")\n" ++
    "                self.cpp_info.components[\"sdl3\"].sharedlinkflags.append(\"-Wl,-weak_framework,CoreHaptics\")\n" ++
    "                self.cpp_info.components[\"sdl3\"].exelinkflags.append(\"-Wl,-weak_framework,CoreHaptics\")\n" ++
    "                if self.settings.os == \"Macos\":\n" ++
    "                    self.cpp_info.components[\"sdl3\"].frameworks.extend([\"ForceFeedback\", \"IOKit\"])\n" ++
    "                elif self.settings.os in (\"iOS\", \"visionOS\", \"watchOS\"):\n" ++
    "                    self.cpp_info.components[\"sdl3\"].frameworks.append(\"CoreMotion\")\n" ++
    "            if self.options.get_safe(\"hidapi\") and self.settings.os in (\"iOS\", \"tvOS\"):\n" ++
    "                self.cpp_info.components[\"sdl3\"].frameworks.append(\"CoreBluetooth\")\n" ++
    "            if self.options.get_safe(\"power\") and self.settings.os == \"Macos\":\n" ++
    "                self.cpp_info.components[\"sdl3\"].frameworks.append(\"IOKit\")\n" ++
    "            if self.options.get_safe(\"metal\"):\n" ++
    "                self.cpp_info.components[\"sdl3\"].frameworks.extend([\"Metal\", \"QuartzCore\"])\n" ++
    "        # Windows links with all libs by default\n" ++
    "        if self.settings.os == \"Windows\":\n" ++
    "            self.cpp_info.components[\"sdl3\"].system_libs.extend(\n" ++
    "                [\n" ++
    "                    \"kernel32\",\n" ++
    "                    \"imm32\",\n" ++
    "                    \"setupapi\",\n" ++
    "                ]\n" ++
    "            )\n"

fn has(values: &Vec[str], value: &str) -> bool:
    for i in 0..values.len() as i32:
        if values[i] == value: return true
    false

// `flag` immediately followed by `name`.
fn has_pair(values: &Vec[str], flag: &str, name: &str) -> bool:
    for i in 0..values.len() as i32 - 1:
        if values[i] == flag and values[i + 1] == name: return true
    false

fn main:
    // The option values of the macOS binary on Conan Center (conaninfo.txt).
    let info = "[settings]\nos=Macos\n[options]\naudio=True\ncamera=True\nhidapi=True\njoystick=True\nmetal=True\npower=True\nshared=False\nvideo=True\n[requires]\nopengl/system\n"
    let options = conan_recipe_options_from_info(info)
    assert(options.values.len() == 8)

    let mac = conan_extract_recipe_link_metadata_for(sdl_fixture(), "Macos", &options)
    for name in ["CoreVideo", "Foundation", "Cocoa", "Carbon", "CoreAudio", "AudioToolbox", "AVFoundation", "UniformTypeIdentifiers", "GameController", "ForceFeedback", "IOKit", "Metal", "QuartzCore"]:
        if not has_pair(&mac.lib_paths, "-framework", name):
            eprint(f"missing -framework {name}")
            assert(false)
    // The weak framework keeps its weakness, and is named once.
    assert(has_pair(&mac.lib_paths, "-weak_framework", "CoreHaptics"))
    assert(not has_pair(&mac.lib_paths, "-framework", "CoreHaptics"))
    // Another OS's branch, and a guard another OS decides, stay out.
    assert(not has(&mac.lib_paths, "UIKit"))
    assert(not has(&mac.lib_paths, "CoreMotion"))
    assert(not has(&mac.lib_paths, "CoreBluetooth"))
    // IOKit is declared twice (joystick, power): one pair.
    var iokit = 0
    for i in 0..mac.lib_paths.len() as i32:
        if mac.lib_paths[i] == "IOKit": iokit += 1
    assert(iokit == 1)
    assert(has(&mac.libs, "pthread"))

    // A shared SDL links its own frameworks: the block's own guard is false.
    let shared = conan_recipe_options_from_info("[options]\naudio=True\nshared=True\n")
    assert(conan_extract_recipe_link_metadata_for(sdl_fixture(), "Macos", &shared).lib_paths.len() == 0)

    // An option the binary does not have is false under get_safe.
    let quiet = conan_recipe_options_from_info("[options]\nshared=False\n")
    let bare = conan_extract_recipe_link_metadata_for(sdl_fixture(), "Macos", &quiet)
    assert(has_pair(&bare.lib_paths, "-framework", "Cocoa"))
    assert(not has(&bare.lib_paths, "CoreAudio"))
    assert(not has(&bare.lib_paths, "Metal"))

    // No option values known (a source build): nothing is guessed.
    let unknown = conan_extract_recipe_link_metadata(sdl_fixture(), "Macos")
    assert(unknown.lib_paths.len() == 0)

    // The Windows list runs over several lines and has no option guard.
    let windows = conan_extract_recipe_link_metadata(sdl_fixture(), "Windows")
    assert(has(&windows.libs, "kernel32"))
    assert(has(&windows.libs, "imm32"))
    assert(has(&windows.libs, "setupapi"))
    assert(windows.lib_paths.len() == 0)
    print("ok")
