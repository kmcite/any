# Example — tasks demo

A small Flutter app showing **any** with theme toggle, form state, repository
CRUD, and selective rebuilds.

**Package docs:** [../README.md](../README.md) ·
[../doc/USAGE.md](../doc/USAGE.md)

## Run

```sh
flutter pub get
flutter run
```

From the repo root:

```sh
flutter run -C example
```

## What it demonstrates

| Feature | Where |
|---------|--------|
| `AnyScope` setup | `lib/main.dart` |
| Mutable state (`ThemePreference`) | `ToggleDarkCommand` |
| Immutable `copyWith` state | `ApplicationState`, task commands |
| Repository `Binding` | `TasksRepository` |
| `AnySelector` on `int` | `features/tasks_list.dart` |
| `context.read` vs `context.of` | widgets vs commands |

## Layout

```
lib/
  main.dart
  commands/
    count.dart          # CountCommand, ToggleDarkCommand
    put_task.dart
    delete_task.dart
    task_input_update.dart
  states/
  repositories/
  models/
  features/
```

Imports:

- Library — `package:any/any.dart`
- Example — `package:example/...`

## Commands (quick reference)

| Command | Effect |
|---------|--------|
| `ToggleDarkCommand` | Flips `ThemePreference.dark` |
| `CountCommand` | Increments scoped `int` via repository |
| `TaskInputUpdate` | Updates draft title/description |
| `PutTask` | Persists task, clears form |
| `DeleteTask(task)` | Removes task from repo + state |