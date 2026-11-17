# Usage guide

How to structure apps with **any**, pick read APIs, and run the example.

**See also:** [README](../README.md) · [CHANGELOG](../CHANGELOG.md) ·
[Example README](../example/README.md)

## Repository layout

| Path | Purpose |
|------|---------|
| `lib/any.dart` | Stable import (`package:any/any.dart`) |
| `lib/*.dart` | Implementation parts |
| `example/` | Runnable demo (`path: ../`) |
| `test/*_test.dart` | Tests per `lib/*.dart` file |
| `test/support/` | Shared test fixtures |

## Mental model

```
AnyScope
├── repositories (Binding)
└── state objects (by runtimeType)
         ↑ read/commit via Ref in Command.call
         ↑ observe via BuildContext.of / AnySelector
```

1. Register **state** and **repositories** in `AnyScope`.
2. Implement **`Command`** subclasses for writes and side effects.
3. **Widgets** use `context.of<S>()` or `AnySelector` to stay in sync.
4. Dispatch with `await context.call(const MyCommand())`.

## `Ref` in commands

`Command.call` receives a **`Ref`**, not a `BuildContext`:

```dart
class AddItem extends Command {
  const AddItem(this.item);
  final String item;

  @override
  Future<void> call(Ref ref) async {
    await ref.get<ItemRepository>().save(item);
    ref.call<ItemListState>(
      (s) => s.copyWith(items: [...s.items, item]),
    );
  }
}
```

| `Ref` | `BuildContext` |
|-------|----------------|
| `ref.of<S>()` | `context.of<S>()` subscribes |
| `ref.get<R>()` | repositories via commands only |
| `ref.call<S>(fn)` | `context.call(Command)` |

## Mutable vs copy-on-write

`ref.call<S>` always bumps the version for `S`, even if the updater returns the
**same instance**. Use that for mutable models:

```dart
class ToggleDarkCommand extends Command {
  const ToggleDarkCommand();

  @override
  void call(Ref ref) {
    ref.call<ThemePreference>((theme) => theme..dark = !theme.dark);
  }
}
```

Prefer **copy-on-write** for large or shared state so each commit is easy to
reason about.

## Choosing a read API

| API | Subscribes? | When to use |
|-----|-------------|-------------|
| `context.of<S>()` | Yes | UI that must update when `S` changes |
| `context.read<S>()` | No | `onPressed`, `onChanged`, one-off reads |
| `context.maybeOf<S>()` | Yes | Optional scope; `null` outside `AnyScope` |
| `AnySelector<S, R>` | Yes to `S` | Rebuild when `selector(state)` changes (`==`) |

**Rule of thumb:** build with `of`; handlers with `read` unless the handler must
trigger a rebuild of the current widget (rare).

## Repositories

```dart
AnyScope(
  repositories: [
    Binding(ApiClient(baseUrl: 'https://api.example')),
    Binding.lazy(() => Database.open()),
  ],
  states: (initRef) => [
    SessionState(token: initRef.get<ApiClient>().anonymousToken),
  ],
  child: const App(),
);
```

`InitRef.get<R>()` is only available inside the `states` builder. It cannot
read or update scope state.

Duplicate **state** or **repository** types throw `ArgumentError` at startup.

## Organizing commands

Typical app layout (see `example/`):

```
lib/
  main.dart           # AnyScope + MaterialApp
  commands/           # one Command per file or feature
  states/
  repositories/
  features/           # widgets; context.call(...) only
```

Keep commands **small and const** when possible (`const SaveDraft()`). Pass
data as constructor fields (`DeleteTask(task)`).

## Example app

```sh
cd example
flutter pub get
flutter run
```

Registered state in the demo:

| Type | Role |
|------|------|
| `ThemePreference` | Mutable dark mode |
| `ApplicationState` | Task form + list |
| `int` | Counter (via `AnySelector`) |

Commands include `ToggleDarkCommand`, `CountCommand`, `PutTask`, `DeleteTask`,
`TaskInputUpdate`.

## Testing

From the package root:

```sh
flutter test
```

Each library part has a matching test file. Widget tests pump `AnyScope` and
assert rebuild counts, selectors, and command side effects.

## Debugging

In debug mode, DevTools shows logs named **`any.scope`**: scope tree on startup,
then each command’s runtime type, scope version, and affected state types.

Logging never includes state or repository **values**.

## Migrating from older versions

If you used **undo/redo** or **mementos**, those APIs were removed — implement
history in your app layer if you still need it.

Rename **`CommandContext`** → **`Ref`** in `Command.call`, and **`InitContext`**
→ **`InitRef`** in the `states` builder.

See [CHANGELOG](../CHANGELOG.md) for the full list.