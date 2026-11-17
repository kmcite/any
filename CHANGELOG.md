# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project loosely follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] — 2026-11-17

### Added

- `CHANGELOG.md` and expanded documentation (`README.md`, `doc/USAGE.md`,
  `example/README.md`).
- Library split into `lib/*.dart` parts with tests mirrored under `test/`.
- In-place **mutable state** updates notify subscribers (same instance re-commit).

### Changed

- **`CommandContext` → `Ref`** — handle passed to `Command.call` (`of`, `get`,
  `call` for state commits). Widget APIs still use `BuildContext`.
- **`InitContext` → `InitRef`** — repository lookup in `states: (initRef) => …`.
- **Implementation layout** — `lib/utils/any.dart` replaced by `part` files
  (`binding`, `command`, `scope`, `any_scope`, `selector`, `context`,
  `logging`).
- Example app uses class-based `Command` types only.

### Removed

- Memento and undo/redo: `ScopeMemento`, `HistoryState`, `Record`, `Undo`,
  `Redo`, and `save` / `saveOnly` / `restore`.
- Functional command dispatch (`CommandFn`, `context.run`).

## [1.1.0] — 2026-11-17

### Added

- `AnyScope` with versioned, type-keyed state and repository `Binding`
  (eager and lazy).
- `Command` / `CommandContext` for synchronous and asynchronous updates.
- `BuildContext` extensions: `of`, `read`, `maybeOf`, `call`.
- `AnySelector` for slice-based rebuilds.
- Undo/redo via `HistoryState`, `Record`, `ScopeMemento` (removed in 2.0.0).
- Debug logging under the `any.scope` developer log name.
- Example tasks app and widget tests.

[Unreleased]: https://github.com/kmcite/any/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/kmcite/any/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/kmcite/any/releases/tag/v1.1.0