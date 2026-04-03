# Crayon Physics Clone Plan

## 1. Goal

Build a small, polished 2D drawing-physics puzzle game in With,
inspired by Numpty Physics and Crayon Physics:

- draw crayon-like strokes directly into the level
- convert strokes into rigid physics objects
- let nearby stroke endpoints auto-joint into pivots
- move a red token to a yellow goal
- ship with a built-in level editor

This should be a demo that proves With can handle:

- real-time input and rendering
- 2D physics over FFI
- geometry processing
- save/load tooling
- a medium-sized game codebase with editor + runtime

## 2. Upstream Baseline

Reference project:

- https://github.com/midzer/numptyphysics

What to preserve from the upstream feel:

- paper background and hand-drawn presentation
- strokes behaving like rigid wire, not filled solids
- mass scaling with stroke length
- endpoint snapping that creates levers, hinges, and pendulums
- distinct stroke classes: ground, token, goal, decor
- built-in level editor
- level packs / collections

## 3. Product Definition

### 3.1 Core Loop

1. Load a puzzle
2. Show red token and yellow goal
3. Player draws one or more strokes
4. Player runs or unpauses physics
5. World settles, swings, falls, rolls
6. Token reaches goal
7. Player retries or advances

### 3.2 MVP Player Actions

- draw a stroke with mouse or touch
- erase the last stroke
- reset the level
- pause / run physics
- place token and goal in editor mode
- save and load custom levels

### 3.3 Success Criteria

The demo is successful when:

- drawing feels immediate and forgiving
- the stroke-to-body conversion is stable
- simple machines work: ramp, lever, pendulum, bridge
- a player can author and solve new levels in-game
- startup-to-play is under 3 seconds on a normal desktop

## 4. Scope

### 4.1 MVP

- single-window desktop build
- fixed camera, single-screen levels
- paper background + crayon stroke rendering
- Box2D-backed physics
- stroke classes:
  - ground
  - normal dynamic stroke
  - token
  - goal
  - decor
- endpoint auto-joints for compatible strokes
- win trigger when token touches goal
- undo-last-stroke
- reset / pause / resume
- simple built-in editor
- text level format
- 15-25 hand-authored original levels

### 4.2 Post-MVP

- rope / chain strokes
- fans / jet streams
- moving hazards
- multi-touch drawing
- community level browser
- replay recording
- native `.npsvg` import / export

### 4.3 Explicit Non-Goals

- networked features
- procedural levels
- mobile-first UI in v1
- exact binary / file compatibility with Numpty Physics at launch
- upstream asset reuse

## 5. Technical Direction

### 5.1 Physics

Use Box2D through a C-facing API.

Why:

- upstream gameplay is already tuned around Box2D behavior
- With has strong C interop
- fastest route to a convincing clone is matching the solver class

Preferred approach:

- use official Box2D C API if available
- otherwise add a tiny C shim exposing only the pieces we need

Do not bind the entire engine up front. Start with a narrow wrapper:

- world create / destroy / step
- body create / destroy
- polygon / edge / circle fixtures
- revolute joints
- contact callbacks
- sleep / awake flags
- collision filtering

### 5.2 Rendering

Use SDL2 for windowing, input, and 2D presentation.

MVP look:

- off-white paper texture
- stroke-color palette with slightly noisy edges
- simple drop shadow or dark outline for readability
- light UI chrome, minimal menus

The renderer should draw from the gameplay model, not the physics
engine directly. Keep the visual stroke path around even after physics
body creation.

### 5.3 Data Model

Core runtime types:

```text
Level
- name
- bounds
- strokes
- metadata

Stroke
- id
- class
- color
- raw_points
- simplified_points
- closed
- dynamic
- joint_flags
- render_style

StrokeClass
- Ground
- Dynamic
- Token
- Goal
- Decor

StrokeBody
- stroke_id
- body_handle
- segment_fixtures
- endpoint_handles

JointLink
- stroke_a
- stroke_b
- endpoint_a
- endpoint_b
- joint_handle
```

Editor / runtime state:

```text
AppState
- mode (menu, play, edit, paused, solved)
- current_level
- history
- active_tool
- pending_stroke
- camera
- sim_state
```

## 6. Stroke Rules

### 6.1 Drawing

While the player drags:

- sample pointer points in screen space
- reject points closer than a small threshold
- render the live stroke immediately

On release:

- simplify points with a geometric tolerance
- reject tiny scribbles
- detect whether endpoints nearly close into a loop
- classify as open or closed
- create physics representation

### 6.2 Physics Representation

Match Numpty Physics behavior closely:

- open strokes become chains of thin rigid segments
- closed strokes remain perimeter wire, not filled area
- length determines mass
- token strokes are heavier / more stable than normal strokes
- ground strokes are static
- decor strokes render only and do not affect simulation

Important constraint:

- the playable feel depends more on stable segment generation than on
  visual fidelity

### 6.3 Auto-Jointing

When a new stroke endpoint lands near another compatible endpoint:

- create a revolute joint
- disable collision between the joined pair
- mark both endpoints as occupied

Compatibility rules:

- token joins only to token
- goal joins only to goal
- normal joins only to non-token, non-goal
- decor never joins

This mirrors the upstream rules described in the README.

## 7. Level Format Plan

Numpty Physics stores levels as SVG-like `.npsvg` files with metadata
and `<path>` elements. For this project:

### 7.1 Native Format

Use a simple text format first, preferably JSON or a compact With-ish
data format:

```text
level:
  name: "Ramp Intro"
  width: 800
  height: 480
  strokes:
    - class: ground
      color: "#101010"
      points: [(0, 440), (800, 440)]
    - class: token
      color: "#ff4444"
      points: [...]
```

Why native first:

- easier to author and debug
- no SVG parser needed for milestone 1
- avoids inheriting upstream format quirks

### 7.2 Import Compatibility

Add a one-way `.npsvg` importer after MVP if needed.

That importer should:

- parse `<path>` elements
- map CSS-style classes to our stroke classes
- preserve colors and metadata where possible
- normalize curves into polyline points

Do not promise perfect round-trip compatibility in v1.

## 8. Editor Plan

### 8.1 Tools

- draw normal stroke
- draw ground
- draw token
- draw goal
- draw decor
- erase / delete selected stroke
- undo / redo
- play / pause
- reset

### 8.2 UX Rules

- left mouse draws
- right mouse or key modifier pans if camera support exists
- toolbar is always visible in edit mode
- switching tools is one click or one key
- editor never blocks the player behind nested dialogs for common tasks

### 8.3 Save / Load

- local level save
- level list grouped by collection
- quick save for current draft
- autosave crash recovery for editor mode

## 9. Module Breakdown

Suggested With module layout:

```text
demo/crayon/app.w
demo/crayon/game.w
demo/crayon/editor.w
demo/crayon/render.w
demo/crayon/input.w
demo/crayon/physics/box2d.w
demo/crayon/physics/world.w
demo/crayon/geometry/path.w
demo/crayon/geometry/simplify.w
demo/crayon/geometry/joints.w
demo/crayon/level/format.w
demo/crayon/level/load.w
demo/crayon/level/save.w
demo/crayon/ui/toolbar.w
demo/crayon/ui/level_select.w
```

Logical ownership:

- `app` owns startup, window, event loop
- `game` owns play-mode simulation and win checks
- `editor` owns tools, draft stroke creation, history
- `physics/*` owns Box2D bridge and body generation
- `geometry/*` owns point cleanup and stroke analysis
- `level/*` owns serialization and collections
- `ui/*` owns menus and toolbar

## 10. Milestones

### Milestone 0: Sandbox

Deliverable:

- blank paper scene
- draw stroke
- convert stroke into Box2D body
- physics step and render

Exit criteria:

- strokes fall and collide
- 60 FPS on desktop with 50+ strokes

### Milestone 1: Playable Puzzle

Deliverable:

- token and goal support
- win detection
- reset / pause / resume
- 5 original levels

Exit criteria:

- complete one full puzzle start-to-finish
- no obvious solver explosions on simple ramps and levers

### Milestone 2: Editor

Deliverable:

- in-game level editing
- save / load
- stroke class palette
- undo / redo

Exit criteria:

- author a new puzzle entirely in-game
- reload it and solve it

### Milestone 3: Content and Feel

Deliverable:

- 15-25 original levels
- improved crayon rendering
- better onboarding and level select
- sound and small success feedback

Exit criteria:

- a new player can discover rules without external docs
- at least 30 minutes of puzzle content

### Milestone 4: Compatibility and Stretch

Deliverable:

- optional `.npsvg` import
- more stroke gadgets
- packaging polish

Exit criteria:

- imported upstream-style level reads correctly enough for testing
- no major architecture rewrite required

## 11. Hard Problems

### 11.1 Stable Stroke Simplification

If simplification is too aggressive:

- player intent is lost
- joints land in the wrong place

If simplification is too weak:

- physics gets noisy
- performance degrades

Plan:

- keep both raw and simplified point arrays
- tune tolerance by screen pixels, not world units
- add a debug overlay showing both

### 11.2 Closed-Loop Behavior

Upstream gameplay depends on closed loops still acting like wire
perimeters, not filled polygons.

Plan:

- treat closed strokes as looped edge chains or thin-segment rings
- do not fill them into convex polygons

### 11.3 Joint Heuristics

The endpoint snap radius determines whether the game feels magical or
frustrating.

Plan:

- expose snap radius in config
- show endpoint highlight before release
- add a debug mode that visualizes candidate joints

### 11.4 Solver Explosions

Many small segments and joints can destabilize the world.

Plan:

- cap segment density per stroke
- clamp minimum segment length
- avoid generating joints on nearly overlapping endpoints
- reuse proven Box2D defaults before inventing custom tuning

## 12. Content Plan

Initial level set:

- tutorial: draw a ramp
- pendulum swing
- bridge support
- counterweight
- rolling ball funnel
- two-step timing puzzle
- token hand-off
- multi-joint lever

Level design rules:

- each early level teaches one new idea
- avoid giant empty screens
- keep restart friction near zero
- prefer elegant solutions over pixel-hunt precision

## 13. Licensing and Asset Policy

Numpty Physics is GPL. That matters.

Safe path:

- use the upstream project as reference only
- write new code in this repo
- create original levels, UI art, paper textures, and sounds
- do not ship upstream fonts, icons, or levels by default

If we later decide to import or distribute upstream assets or levels:

- review GPL obligations explicitly
- keep imported content clearly separated
- document provenance per asset pack

## 14. Validation Checklist

Before calling the demo complete:

- drawing latency feels immediate
- endpoint snapping feels intentional
- reset is instant
- win detection is obvious
- no common level causes simulation blow-up
- authored levels load deterministically
- editor save format is human-readable
- code is split cleanly between editor, runtime, and physics bridge

## 15. Recommendation

Build this in two passes:

1. physics sandbox + one puzzle, using SDL2 + Box2D through a narrow FFI
2. editor, content, and presentation polish

The highest-risk work is not rendering. It is:

- stroke simplification
- stroke-to-body conversion
- endpoint joint heuristics

If those three systems feel right, the rest of the project is
straightforward. If they feel wrong, no amount of UI polish will save
the demo.
