# Usage guide

This guide walks through how to structure a Flutter app with **any**, how to
choose between `of`, `read`, and `AnySelector`, and how to run the included
example.

## Project layout

| Path | Purpose |
|------|---------|
| `lib/any.dart` | Stable public import (`package:any/any.dart`) |
| `lib/utils/any.dart` | Library implementation |
| `example/` | Runnable tasks demo that depends on `path: ../` |
| `test/` | Widget and unit tests for the package |

## Mental model

1. Register immutable (or copy-on-write) state objects and repositories in
   `AnyScope`.
2. Put side effects and updates in `Command` subclasses.
3. Read state from widgets with `context.of<S>()` or narrow with `AnySelector`.
4. Dispatch work with `await context.call(MyCommand())`.

Commands receive a `CommandContext` with the same capabilities as
`BuildContext` extensions (`of`, `get`, `call`, mementos).

## Choosing a read API

| API | Subscribes? | When to use |
|-----|-------------|-------------|
| `context.of<S>()` | Yes | Building UI that must update when `S` changes |
| `context.read<S>()` | No | Callbacks, one-off reads, `initState` follow-ups |
| `context.maybeOf<S>()` | Yes | Optional scopes, shared widgets used inside and outside `AnyScope` |
| `AnySelector<S, R>` | Yes, for `S` | Rebuild only when `selector(state)` changes (by `==`) |

Use `context.read` inside `onPressed`, `onSubmitted`, and repository listeners
when you do not want an extra rebuild dependency.

## Repositories

```dart
AnyScope(
  repositories: [
    Binding(ApiClient(baseUrl: 'https://api.example')),
    Binding.lazy(() => Database.open()),
  ],
  states: (init) => [
    SessionState(token: init.get<ApiClient>().anonymousToken),
  ],
  child: const App(),
);
```

`InitContext.get<R>()` is available only while building the initial state list.
It cannot read or mutate scope state.

## Undo and redo

Register `HistoryState`, wrap mutating commands in `Record<S>`, and dispatch
`Undo<S>` / `Redo<S>`:

```dart
await context.call(
  Record<ApplicationState>(
    PutTask(id, title, description),
    debounce: const Duration(milliseconds: 400),
    groupKey: 'task-edit',
  ),
);
```

`debounce` merges rapid edits into one history step when `groupKey` matches.

## Running the example

```sh
cd example
flutter pub get
flutter run
```

The example registers:

- `ThemePreference` — dark/light mode toggled from the app bar
- `ApplicationState` — task form and list
- `TasksRepository` — in-memory task store
- `HistoryState` — ready for recorded commands
- `int` — quick-action counter (shown via `AnySelector`)

## Debugging

In debug builds, scope creation and command results log under the
`any.scope` name in DevTools. Logging never includes state or repository
values—only types, versions, and affected state keys.