# Steam Dev: Deploy, Run, Debug and Reload on a Steam Deck

## Scope

One command loop takes a game from the developer's machine to a Steam Deck
on the desk and back:

```text
with dev pair deck                 # once: keys, tools, a name for the device
with dev run deck                  # build for the Deck, push, launch in Game Mode, stream its output
with dev debug deck                # the same, stopped at main under LLDB on the developer's machine
with dev watch deck                # edit, save, and the running game picks up the change
```

The link is the one Valve supports for development: Wi-Fi, or wired
Ethernet through a USB-C hub (§3.4). The bar is that this feels effortless:
one tap on the Deck to pair, no passwords, no BIOS, no Desktop Mode.

This is the development loop around the game toolkit
(`docs/plans/game-toolkit.md`), the part that Milestone 4 of that plan
("the Deck, end to end") needs every day and that no native language
ships. Valve's SteamOS Devkit Client covers pairing and upload for
engines that integrate it; it has no notion of a With build, a With
recording or a With debugger session.

The shape is a device seam, like the toolkit's `Platform` seam: the Deck is
the first backend, a desktop Linux machine over SSH comes free with it, and
console devkits are slots that fail loudly until a vendor backend exists.

Eric asked for this on 2026-10-18. This is a plan, not a specification.
Paths are relative to the `with` repository unless they name WIPE.

## 1. What exists and what doesn't

### 1.1 In With today

| Need | State | Where |
|---|---|---|
| Source-level debug info | **Emitted by default; no `-g` flag exists or is needed.** Verified on macOS arm64 (v0.15.3.0, 2026-10-18): `with build -O0` gives a `.dSYM`, line breakpoints in `.w` files, `frame variable` with parameters and locals, and a backtrace in With source. The default build optimizes, so small functions are inlined and a breakpoint on their lines has no location; a dev build is `-O0`. `--release` writes no `.dSYM`. | `docs/completed/debug.md`, `test/behavior/behav_debug_info_variables.w` |
| Build for `linux_x86_64` from a Mac | **Not possible for a game yet.** `BuildTarget.linux_x86_64` exists, and the link stage already takes a Linux sysroot (`WITH_LINUX_SYSROOT`, `src/compiler/Link.w:385-412`) and the bundled `ld.lld`. What refuses is `c_import` under `--target` (`src/CImport.w:754`: it would parse the host's headers), and Conan selection uses the host OS. `with build :cross` fails loudly. | `src/CImport.w`, `src/compiler/Link.w`, `docs/spec/toolchain/with-build.md` §Cross-Platform Targets |
| A Linux build that runs on the Deck | Proven by WIPE: built **on the Deck** with the Deck's own With install, `libsteam_api.so` beside the executable with an `$ORIGIN` rpath. This is the only deployment path used so far. | WIPE `build.w`, `docs/steam-and-steam-deck-support.md` §8 |
| Shared-library output and a loader | None | — |
| Hot reload | None. `docs/proposals/with-ui.md` proposes state-as-snapshot reload for UI; nothing is built. | — |
| Deterministic recording and exact replay | Proven in WIPE; becomes `game.record` | WIPE `src/record.w` |
| An editor integration | `with-vscode`, `with lsp` | `with-vscode/` |

### 1.2 On the Deck (probed 2026-10-18)

Eric's Deck, read over SSH after pairing:

| Fact | Value |
|---|---|
| Model, BIOS | LCD (`Jupiter`), F7A0133 |
| OS | SteamOS 3.8.28 (build 20260922.1), kernel 6.18.50-valve2, read-only root |
| CPU, memory | AMD Custom APU 0405, 8 threads; 14 GiB |
| With | `~/.local/bin/with`, v0.15.3.0, the same as the Mac; LLVM 22.1.6 with `ld.lld` under `~/with/.deps/`, which is why it links with no `cc` (there is none) |
| Debug server | `/usr/bin/gdbserver` ships with SteamOS; no `lldb-server` |
| Sync | `/usr/bin/rsync` ships with SteamOS |
| Devkit Service | Running: Developer Mode was on. Advertises `_steamos-devkit._tcp` over mDNS, serves HTTP on port 32000 |
| SSH | Off until a pairing turns it on (§3.2) |
| Wi-Fi | 2.4 GHz channel 11, 20 MHz, power saving on: tx 52 Mbit/s, ping 13-75 ms. The Mac was on 5 GHz at 1080 Mbit/s on the same network |

What this means:

- **Pairing is Valve's, and it is the effortless part.** The Devkit Service
  is SteamOS's adb. `POST /register` with a public key makes Steam show a
  "Development host pairing" prompt on the Deck; one tap accepts it, and the
  service then turns sshd on (`steamos-enable-sshd`) and appends the key to
  `~deck/.ssh/authorized_keys`. No password, no Desktop Mode. Verified on
  this Deck. The service accepts only `ssh-rsa` keys (`write_key` rejects
  anything else), so the toolchain makes an RSA key for it.
- **Game Mode is the only real environment.** Steam Input, the overlay and
  gamescope's 1280×800 output exist only there, so the launch goes through
  Steam (§3.3), never `ssh deck ./game`.
- **USB-C as a direct data link is not a supported path.** The port is
  fixed as an xHCI host at boot (PCI `1022:162c`); `dwc3-pci`, the driver
  for device mode, binds only `1022:163a`, which the firmware presents
  only when the BIOS's *USB Dual Role Device* is set to DRD. SteamOS and
  the Steam client offer no toggle for it (searched the system tools and
  the client's UI strings), and Valve's devkit documentation names Wi-Fi
  and hub Ethernet only. The kernel does ship `libcomposite` and
  `usb_f_ncm`, and Valve's own `usbhid-gadget-passthru` is installed, so it
  is possible; it is not supported. Decided 2026-10-18: not this plan.

### 1.3 What other toolchains do

| Toolchain | Deploy | Debug | Reload |
|---|---|---|---|
| SteamOS Devkit Client | mDNS discovery; `POST :32000/register` and an on-Deck approval install the key and start sshd; rsync upload; `steam://devkit-1/create-shortcut` over Steam's IPC pipe registers the game in Game Mode | Can install `gdbserver` sessions; no source-level client of its own | No |
| Godot DeployToSteamOS | Rides the Devkit Client's keys | No | No |
| Unreal / Unity | Their own device managers | Native remote debuggers | Live Coding (Unreal), domain reload (Unity) |
| Odin / Handmade Hero pattern | — | — | Game as a shared library, host keeps memory, `dlopen` on change |
| Xbox / PlayStation / Switch devkits | Vendor tool: pair, push, launch | Vendor debugger over the devkit link | Vendor-specific |

The consoles all present the same four verbs: pair, deploy, launch,
attach. That is the seam.

## 2. Design rules

1. **Valve's path, then SSH.** Pairing uses the Devkit Service's
   approval; every verb after it is SSH, `rsync` over SSH, or a port
   forwarded through SSH. The toolchain adds nothing that listens on the
   Deck's network.
2. **Run where players run.** `with dev run` launches through Steam in Game
   Mode. Desktop Mode is a flag (`--desktop`) for when gamescope is the
   suspect, and it says so in its output.
3. **The same binary.** What `with dev run` pushes is what `with build`
   packages: the allowlist of `game.package`, the Steam library beside the
   executable, the same rpath. A dev build differs only in debug info and
   the dev channel (§5), both stated in the build's output.
4. **No root, no residue.** The toolchain's files on the Deck live in
   `~/.local/share/with-dev/`. `with dev unpair` removes them and the
   Game Mode shortcut it made, and lists anything it could not remove.
5. **Fail loudly at the first wrong fact.** No device, wrong architecture,
   SSH off, Game Mode not running, a build that is not Linux x86_64: each
   is an error naming the fact and the fix, before anything is copied.
6. **Reload is correct or it is a restart.** A reload that keeps state
   whose layout changed is a plausible wrong thing (mission rule 7). Every
   reload path says which kind it did, and the fallback is always a clean
   restart.
7. **No `unsafe` in a game, still.** Toolkit rule 10 holds: the dev channel,
   the reload host and the device code live in the toolchain and the
   `game` package behind facades. A capability that needs `unsafe` in the
   developer's code is a compiler issue to file.
8. **Devices are typed.** `deck`, `linux`, and console slots are a closed
   enumeration; a device entry in `with.toml` names its kind. A console
   kind fails with `comptime_error`-style diagnostics until its private
   backend is installed, as in the toolkit's §4.2.

## 3. The command surface

### 3.1 Devices are project facts

```toml
# with.toml
[devices.deck]
kind = "steam-deck"
host = "steamdeck.local"     # or an address; written by `with dev pair`
user = "deck"
```

The key lives in `~/.config/with/dev/` on the developer's machine, never
in the project. A device named on the command line that is not in
`with.toml` is looked up in the user's paired devices.

### 3.2 The verbs

| Command | Does |
|---|---|
| `with dev pair [<name>]` | Finds every Deck advertising `_steamos-devkit._tcp`; with one, uses it, with several, asks which. If the service does not answer, says exactly where the toggle is (Settings → System → Developer Mode, then Developer → Development host pairing). Posts the toolchain's RSA key to `/register`, prints "Approve the pairing on your Deck", and waits for the tap. Then checks SteamOS on x86_64, installs `lldb-server` into `~/.local/share/with-dev/`, records the device. Idempotent; a second run on a paired Deck is silent. |
| `with dev status <name>` | Reachable? Game Mode or Desktop? Free space, battery, the installed tool versions, the last build pushed. |
| `with dev deploy <name>` | Builds the Linux package (§4), `rsync`s it by content hash into `~/.local/share/with-dev/games/<project>/`, creates or updates the Game Mode shortcut. Prints bytes sent. |
| `with dev run <name> [-- args]` | `deploy`, then launches through Steam, then streams stdout, stderr and the game's log to the terminal until the game exits; Ctrl-C stops the game, not just the stream. Exit status is the game's. |
| `with dev debug <name>` | `run` with the game started under `lldb-server`, stopped before `main`; starts LLDB here connected through an SSH port forward, with the source map and symbols set (§6). `--attach` attaches to the running game instead. |
| `with dev watch <name>` | `run`, then watches sources and assets; on save, reloads by the strongest correct tier (§7) and prints which one it used. |
| `with dev logs <name>` | Re-attaches the stream to a running game. |
| `with dev shell <name>` | SSH into the device in the game's directory. |
| `with dev pull <name> <what>` | Copies back saves, recordings, crash dumps, screenshots. `with dev pull deck recording` is how a Deck-only bug becomes a desktop replay. |
| `with dev unpair <name>` | Rule 4. |

`with dev` is a new top-level verb beside `run` and `test`. Whether it
should instead be `with run --device deck` is open question 1; the verbs
`pair`, `debug`, `watch`, `pull` have no home in `run`, which argues for
the verb.

### 3.3 The Game Mode launch

The shortcut runs a launcher script the toolchain owns
(`~/.local/share/with-dev/launch.sh <project>`). Steam starts the script
inside gamescope with Steam Input and the overlay; the script reads a
per-launch file the developer's side wrote (arguments, whether to start
under `lldb-server`, the dev channel port) and `exec`s the game. The
shortcut never changes between runs, so Steam's controller configuration
for it persists.

The mechanism is the one the Devkit Client uses, read from its
`devkit-utils`: a line `devkit-1 steam://devkit-1/create-shortcut?...`
written to the Steam client's IPC pipe `~/.steam/steam.pipe`, with the
reply arriving as a file the client writes. The same pipe carries the
launch and `dumpcontrollerconfig`. Whether the toolchain drives the pipe
itself or installs Valve's helper scripts is open item 5 of Milestone 0;
both work without Desktop Mode, and neither writes `shortcuts.vdf`.

### 3.4 The link

| Link | State |
|---|---|
| Wi-Fi | Supported by Valve; measured below |
| Wired Ethernet through a USB-C hub or dock | Supported by Valve; same commands |
| USB-C cable straight to the Mac | Not supported (§1.2); not offered |

Measured on Eric's network, 2026-10-18: pushing a 9 MB file (WIPE's
executable is 8,980,144 bytes) took 2.4 s, 9.0 s and 10.8 s on three runs;
`rsync -z` of WIPE's 18.9 MB of sources and assets took 10.6 s. The Deck
was on 2.4 GHz with power saving on. Two consequences:

- `with dev status` reports the band, bit rate and power-save state, and
  says when the Deck is on 2.4 GHz while the Mac is on 5 GHz. During a
  session `with dev run` turns power saving off through Valve's own helper
  (`steamos-disable-wireless-power-management`, which the Devkit Client
  uses) and says so.
- Pushes are content-addressed and compressed: only changed files move, and
  an unchanged executable is never sent twice.

## 4. Building for the Deck

### 4.1 Measured

WIPE at `5653888`, v0.15.3.0 on both ends, 2026-10-18:

| | Deck (8 threads) | Mac (Apple M5 Max, 18 cores) |
|---|---|---|
| Clean build of `:wipe` | 66.8 s (peak RSS 411 MB) | 20.4 s |
| One real edit (a function added to `src/presentation.w`) | 65.5 s | 18.1 s |
| No change | 0.4 s | — |

Any source change rebuilds the whole executable; there is no per-module
reuse inside a target today, and a comment-only edit is correctly a no-op.
So the Mac builds 3.6× faster. With a push of 2.4-10.8 s on this Wi-Fi
(§3.4), a Mac build plus push is 21-29 s against 65 s on the Deck. That
is why cross-building is the target and the Deck builder is the interim.
Rebuilding only what changed would help both; where those 18 s go and
the staged way to cut them is `docs/plans/incremental-compilation.md`.

### 4.2 The target: cross-build on the Mac

Valve publishes the sysroot: `repo.steampowered.com/steamrt4/images/<version>/`
carries `com.valvesoftware.SteamRuntime.Sdk-amd64,i386-steamrt4-sysroot.tar.gz`
(1.12 GB; the runtime-only `Platform` sysroot is 314 MB). The latest,
4.0.20261007.263973, holds everything WIPE links against: glibc and its
crt objects, GCC 14's `crtbegin.o`, SDL3 3.4.18 (shared and static), GL,
EGL, X11, Wayland, Vulkan, ALSA, PulseAudio and udev headers and
libraries. Building against it is also what Valve recommends for native
games (WIPE `docs/steam-and-steam-deck-support.md` §8).

The compiler work, each an issue to file:

1. **`c_import` under `--target`** parses headers with the target triple
   and the sysroot (`--sysroot`, `-isystem <sysroot>/usr/include`) instead
   of refusing (`src/CImport.w:754`). This is the one hard piece: layouts,
   macros and `#if __linux__` must come from the target, never the host.
2. **Target-keyed C dependencies.** Conan selection takes the target, and
   `.with/deps/c/<name>/<version>` gains a target key. raylib and SDL3 for
   `linux-x86_64` come from Conan as on a Linux host, or SDL3 from the
   sysroot itself.
3. **The sysroot as a fetched artifact.** `with.toml` names it
   (`[targets.steam-deck] sysroot = "steamrt4@4.0.20261007.263973"`); the
   toolchain downloads it once into a shared cache, verifies it against the
   `.mtree.gz` Valve publishes beside it, and passes it to the link stage
   that already reads `WITH_LINUX_SYSROOT`.
4. **The link with the bundled `ld.lld`** and that sysroot, so no Linux
   `cc` is needed on a Mac. The Linux link path already uses the sysroot's
   crt objects and dynamic linker (`src/compiler/Link.w:385-420`).

When these land, the device's `build` defaults to `cross`.

### 4.3 Until then: build on the Deck

The Deck builder automates what Eric does by hand today. `rsync` the
project's sources and assets (not `out/` or `.with/`) to
`~/.local/share/with-dev/src/<project>/`, run `with build` there over SSH,
run the result in place. `pair` checks the Deck's `with version` against
the Mac's and offers to install the matching compiler under `~`. The
Deck's `.with/deps` and build cache persist. The DWARF then names Deck
paths, which §6's source map maps back to the checkout.

Every builder runs `with build` on the same `build.w`, so the program that
decides what a package is never forks.

## 5. The dev channel

A dev build of a toolkit game opens one TCP port on the Deck's loopback
only, reached through the SSH forward. It carries a small framed protocol
owned by `game.dev`:

| Message | Use |
|---|---|
| `log` (game → host) | Structured log lines, so `with dev run` does not depend on Steam capturing stdout |
| `step` (game → host) | The simulation step and frame time, for `with dev status` and the watch HUD |
| `pause` / `resume` / `step N` | Freeze the fixed-step clock, advance exactly N steps |
| `snapshot` / `restore` | Tier 2 of §7 |
| `record start` / `stop` / `pull` | Recordings without touching the game's menus |
| `reload asset <path>` | Tier 1 of §7 |
| `screenshot` | The frame as the player sees it, gamescope included |

A release build does not contain `game.dev`: the module is excluded by the
build, not disabled by a flag, and the packaging step refuses a release
package that links it.

## 6. Debugging

- **What works today**: DWARF is on by default and LLDB reads it (§1.1):
  line breakpoints, parameters, locals and backtraces in With source,
  verified on the Mac at `-O0`. So the only build change for debugging is
  the optimization level: `with dev debug` builds `-O0`, and `with dev run`
  keeps the default so the Deck's frame rate is the real one.
- **The server**: `lldb-server` for Linux x86_64 from the LLVM release the
  compiler already uses (22.1.6), installed by `pair` into the device
  directory, so both ends are one LLVM version. SteamOS's preinstalled
  `/usr/bin/gdbserver` is the fallback; LLDB speaks its protocol
  (`gdb-remote`). Whether the Deck's With LLVM tree includes `lldb-server`
  was not checked; if not, `pair` copies it.
- **The session**: `with dev debug` forwards the server's port over SSH,
  then runs LLDB here with `platform select remote-linux`, the executable
  with its DWARF, and `settings set target.source-map <builder path>
  <project path>` so a cross or Deck build still shows local files.
- **Symbols**: the dev package is stripped for the push; the unstripped
  executable stays on the developer's machine and LLDB loads it by build
  ID. The push stays small and the debugger has everything.
- **The editor**: `with-vscode` gains a launch configuration that calls
  `with dev debug --dap`, which serves `lldb-dap` instead of the LLDB REPL.
  Breakpoints set in the editor survive a `watch` restart (§7, tier 3).
- **What With must provide**: Phase 1 debug info covers lines and locals.
  Struct and enum type graphs, `Option`/`Result` and slice pretty-printing
  are not built. Inspecting a `Handle[T]` or a `Vec[T]` usefully needs
  them, and LLDB data formatters shipped with the toolchain. Each missing
  piece found while debugging WIPE on the Deck is an issue.
- **Crashes without a debugger**: the launcher enables core dumps into the
  device directory; `with dev pull deck crash` brings the core and LLDB
  opens it against the local symbols.

## 7. Hot reload

Three tiers, strongest correct one first. `watch` decides per change and
prints its decision.

### Tier 1: assets (always correct)

A changed file under the package's asset allowlist is pushed, then
`reload asset <path>` tells `game.audio` and the texture loader to replace
it. A game opts a loader in by giving it a reload hook; an asset with no
hook falls to tier 3.

### Tier 2: code, by restart and replay (correct by construction)

The toolkit already has what makes this sound: a fixed-step simulation and
exact replay. On a code change:

1. The running game records continuously in dev builds (`game.record`).
2. The new build is pushed and launched.
3. The new process replays the old process's recording headless to the
   same step, then hands control to the pad.

If the change did not touch the simulation, the replay lands in the same
state and the developer sees their edit at the moment they left. If it did,
the replay runs the new rules over the same inputs, which is the honest
answer to "what would have happened". The state is never copied across a
layout change, so rule 6 holds without schema migration. `snapshot` /
`restore` shortens long sessions when the snapshot's type hash matches;
otherwise replay from the start, and say so.

Costs: the build is measured (§4.1): 18 s plus a push on the Mac, 65 s on
the Deck, for WIPE. Still to measure in Milestone 3: Steam relaunch time
in Game Mode, and replay speed for a ten-minute session. At these build
times tier 2 is a 20-30 s loop; tier 1 and the dev channel's `pause` /
`step N` are what make tuning feel instant.

### Tier 3: code, in process (later, and only if tier 2 is too slow)

The Handmade Hero shape: a host executable owns the window, devices and
memory; the game is a shared library loaded with `dlopen` and replaced on
change, keeping the process, the Steam session and the debugger attached.
It needs With to:

1. Emit a shared library with a stated, versioned entry ABI.
2. Load one through a facade, so the host has no `unsafe` (rule 7).
3. Refuse a reload whose state types' layouts differ, by a type hash the
   compiler emits, falling to tier 2.

None of this exists. It is listed so the plan does not pretend tier 2 is
the ceiling, and it is not scheduled until tier 2's measured loop is too
slow to use.

## 8. Milestones

### Milestone 0: spikes, answered on a real Deck

Answered 2026-10-18 on Eric's Deck:

1. ~~USB network gadget~~: not supported by Valve; dropped (§1.2).
2. Pairing without a password: **yes**, through the Devkit Service (§1.2).
3. Build times: **measured** (§4.1).
4. Debug info: **works** on the Mac at `-O0` (§1.1).

Still open:

5. Launching in Game Mode over Steam's IPC pipe (§3.3) from the toolchain's
   own code, without Valve's helper scripts installed.
6. `lldb-server` from LLVM 22.1.6 runs from `~` on SteamOS, and LLDB on the
   Mac attaches to a WIPE Linux build through an SSH forward, with source
   lines.
7. A one-shot manual cross-build: WIPE's object files from the Mac with
   `c_import` pointed by hand at the steamrt4 sysroot, linked with `ld.lld`,
   run on the Deck. It shows how far issue 1 of §4.2 really is.

### Milestone 1: deploy and run

1. `with dev pair`, `status`, `deploy`, `run`, `logs`, `shell`, `unpair`
   for `kind = "steam-deck"` and `kind = "linux"`.
2. The Deck builder (§4.3).
3. WIPE runs on the Deck in Game Mode from `with dev run deck` on a Mac,
   with its output in the Mac's terminal.
4. Tests: a fake device (a Linux container with SSH) in the battery, so
   every verb runs without hardware; the Deck acceptance is a UAT.

### Milestone 2: debug

1. `with dev debug`, `--attach`, crash pull, the source map.
2. The `with-vscode` launch configuration over `lldb-dap`.
3. WIPE: a breakpoint in `src/game.w` hit on the Deck, a local variable
   printed, a step over, from the Mac. Every value LLDB cannot show
   usefully is filed.

### Milestone 3: the dev channel and reload tiers 1 and 2

1. `game.dev` in the `game` package, excluded from release packages.
2. `with dev watch` with asset reload and restart-and-replay.
3. The three costs of §7 tier 2, measured on WIPE and written here.

### Milestone 4: cross-building

The four issues of §4.2. It may run beside Milestones 2 and 3, since it
touches the compiler and they touch the toolchain. It is done when
`with dev run deck` on the Mac builds on the Mac, and the Deck only runs.

### After this plan

Tier 3 reload, if Milestone 3's numbers ask for it. Console device kinds,
each a private backend implementing the same four verbs.

## 9. Acceptance

- On a Mac with a paired retail Deck, `with dev run deck` in a project
  generated by `with init --type game` builds, pushes and launches the game
  in Game Mode with Steam Input, and its log appears in the Mac's terminal.
- `with dev debug deck` stops at `main`; a breakpoint set in the editor on
  a line of `src/` is hit on the Deck and shows locals.
- Under `with dev watch deck`, saving a texture changes it in the running
  game without a restart; saving a source file brings the game back at the
  same simulation step it left, and the terminal says which tier ran.
- `with dev pull deck recording` followed by a desktop replay reproduces
  the Deck session exactly.
- `with dev unpair deck` leaves nothing of the toolchain on the Deck.
- A release package built by the same project contains no `game.dev`.
- Every verb runs in the battery against the fake device.

## 10. Open questions

1. `with dev <verb>` or `with run --device` plus separate verbs.
2. ~~Require Valve's Devkit Service~~: yes, decided 2026-10-18. It is the
   supported path and the effortless one.
3. Whether `[devices]` belongs in `with.toml` (shared with the team) or
   only in the user's config (addresses are personal). The proposal keeps
   the kind in the project and the address in the user's config.
4. Recording always on in dev builds: memory and disk on a long session.
5. Whether the dev channel should be the toolkit's or the compiler's (a
   general `with run --remote` for any program).

## 11. Advice that does not apply

| Advice | Why not |
|---|---|
| "Launch over SSH into Desktop Mode, it's simpler." | Not where players run (rule 2): no Steam Input layout, no overlay, no gamescope. Available as `--desktop`, labeled. |
| "Copy the state across a reload and hope the layout matches." | Rule 6. Restart-and-replay is correct by construction because the toolkit has exact replay. |
| "Make the Deck a USB network device so builds go over the cable." | Possible (the kernel has the gadget modules) but unsupported: it needs the BIOS DRD switch and root gadget setup, and Valve documents only Wi-Fi and hub Ethernet. Decided 2026-10-18: Valve's path. |
| "Pair by asking for the `deck` password." | The Devkit Service's on-Deck approval does the same with one tap, and is Valve's. |
| "Expose a debug port on the network for convenience." | Rule 1. Everything rides the SSH connection the developer authenticated. |

## 12. References

- `docs/plans/game-toolkit.md`: the `game` package, `game.record`,
  `game.package`, the `Platform` seam this plan's device seam mirrors.
- WIPE: SURVIVAL `docs/steam-and-steam-deck-support.md` §8 (the Linux build)
  and §9 (the Verified checklist).
- Valve, SteamOS Devkit Client and Service (open source, GitLab); Steamworks
  partner docs, "Loading and running games on Steam Deck".
- SteamOS Devkit Service source (mirror `evlaV/steamos-devkit-service`):
  `/register`, the `approve-ssh-key` and `install-ssh-key` hooks.
- SteamOS Devkit Client source (mirror `flibitijibibo/steamos-devkit`):
  `client/devkit-utils/` (`steam-client-create-shortcut`, `steam-devkit-rpc`,
  the `steam.pipe` protocol in `devkit_utils/__init__.py`).
- Steam Linux Runtime 4 images: `https://repo.steampowered.com/steamrt4/images/`.
- Godot DeployToSteamOS: a third-party deploy riding the Devkit Client.
- On the USB gadget path: `dafta/DeckMTP`, `jmedina21/deck-as-controller`,
  and Valve's `usbhid-gadget-passthru` (on SteamOS).
