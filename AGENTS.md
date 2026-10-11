# Project guidance

## Project

This is a Godot 4 VR bellringing simulator built with OpenXR and Godot XR Tools. The intended experience is to let players learn and practise change ringing by physically handling bell ropes in a convincing bell tower.

The current project is an early foundation: `main.tscn` is the entry scene and `Entities/player.tscn` contains the XR origin, camera, controllers, hands, pickup interactions, and locomotion. Treat the existing XR setup as the starting point; add simulator content around it rather than replacing it without a clear need.

## Product direction

- Make the core interaction physical and readable in VR: rope motion, pull timing, bell response, and feedback should be easy to understand from the player's position.
- Support learning as well as free practice. Prefer clear, forgiving feedback and configurable assistance over unexplained failure states.
- Keep comfort and accessibility in mind: avoid forcing camera motion, provide sensible seated/standing and reach options where practical, and make important visual or audio cues perceivable in more than one way.
- Aim for a believable bell tower atmosphere while keeping controls and learning aids legible and uncluttered.

## Technical conventions

- Use Godot 4 scene-based composition. Keep gameplay entities and reusable interactions in their own scenes/scripts rather than growing `main.tscn` into a monolith.
- Prefer proper, off-the-shelf solutions: check Godot's built-in features and the installed XR Tools addon before designing custom logic. If custom logic appears necessary, raise the need and proposed approach with the project developer first so they can check for a standard solution; wait for that review before implementing it.
- Make scene structure visible and editable in the Godot editor. Author nodes, physics bodies, joints, grab points, and their relationships in `.tscn` scenes instead of constructing the structure invisibly at runtime in code. Use scripts for behavior that genuinely needs code, and preserve an editor preview for generated visuals where practical.
- The project uses OpenXR, Godot XR Tools, Jolt Physics, and the GL Compatibility renderer. Preserve compatibility with the Android export target and current XR configuration when adding features.
- Keep project-authored code and assets distinct from vendored content under `addons/`. Do not modify addon files to implement project-specific behavior when a project-owned wrapper or scene can do it.
- Prefer clear node names and small scripts with explicit responsibilities. Keep tunable gameplay values exported or in appropriate resources instead of burying them in unrelated logic.
- For bell and rope physics, favor stable, frame-rate-independent behavior and test interaction at realistic VR scale. Avoid relying on tiny collision geometry or timing that assumes a particular headset refresh rate.
- Preserve existing input action and controller conventions unless a feature requires a deliberate, documented change.

## Working in this repository

- The Godot project configuration is in `project.godot`; the main scene is `main.tscn`.
- Organize new project-owned scenes, scripts, and assets in clear folders such as `Entities/`, `Environment/`, `Systems/`, and `Audio/` as those areas are introduced. Match existing capitalization when touching established paths.
- Do not commit generated `.godot/` editor/import cache files.
- When changing a scene or project setting, keep resource references and Android/OpenXR export configuration consistent.
