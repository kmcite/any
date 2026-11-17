# any

`any` is a lean state-management library for Flutter built around three ideas:

1. **`AnyScope`** holds application state and repositories.
2. **`Command`** classes perform work and commit state changes through a
   `CommandContext`.
3. **Widgets** observe state via `BuildContext` extensions and rebuild only for
   the state types they subscribe to.

For a longer walkthrough, see [doc/USAGE.md](doc/USAGE.md). A full demo lives in
[`example/`](example/).

## Installation

```yaml
dependencies:
  any:
    git:
      url: https://github.com/kmcite/any.git
```

```sh
flutter pub get
```

Import the public API:

```dart
import 'package:any/any.dart';
```

## Quick start

```dart
import 'package:any/any.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    AnyScope(
      states: (init) => [
        CounterState(count: init.get<CounterRepository>().initialCount),
      ],
      repositories: [Binding(CounterRepository())],
      child: const MaterialApp(home: CounterPage()),
    ),
  );
}

class CounterState {
  const CounterState({this.count = 0});
  final int count;
  CounterState copyWith({int? count}) =>
      CounterState(count: count ?? this.count);
}

class CounterRepository {
  int get initialCount => 0;
  int nextCount(int current) => current + 1;
}

class IncrementCounter extends Command {
  const IncrementCounter();

  @override
  void call(CommandContext context) {
    final current = context.of<CounterState>().count;
    final next = context.get<CounterRepository>().nextCount(current);
    context.call<CounterState>((state) => state.copyWith(count: next));
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.of<CounterState>().count;

    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.call(const IncrementCounter()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Scope setup

```dart
AnyScope(
  states: (init) => [
    CounterState(count: init.get<CounterRepository>().initialCount),
    const HistoryState(),
  ],
  repositories: [
    Binding(CounterRepository()),
    Binding.lazy(() => HeavyService()),
  ],
  child: const MyApp(),
)
```

- **`states`** runs once at startup. Objects are keyed by **runtime type**; only
  one instance per type is allowed.
- **`InitContext.get<R>()`** resolves repositories during initialization only.
- **`Binding(instance)`** is eager; **`Binding.lazy(() => …)`** creates on first
  `get`.

## Commands

Extend `Command` and implement `call(CommandContext context)` (sync or async):

| Method | Purpose |
|--------|---------|
| `context.of<S>()` | Read current state |
| `context.get<R>()` | Read repository |
| `context.call<S>(updater)` | Commit new state for `S` |
| `context.save()` / `saveOnly<S>()` | Capture mementos |
| `context.restore(memento)` | Restore captured state |

Return new values from updaters; avoid mutating existing state in place.

## Widget API

| Method | Subscribes? | Purpose |
|--------|-------------|---------|
| `context.of<S>()` | Yes | Build UI that tracks `S` |
| `context.read<S>()` | No | One-off read in callbacks |
| `context.maybeOf<S>()` | Yes | Same as `of`, or `null` without a scope |
| `context.call(command)` | No | Run a command |
| `context.save()` / `saveOnly<S>()` / `restore(...)` | No | Memento helpers |

### Selective rebuilds

`AnySelector` subscribes to `S` but only runs `builder` when the selected value
changes (`==`):

```dart
AnySelector<CounterState, int>(
  selector: (state) => state.count,
  builder: (context, count) => Text('$count'),
)
```

## Undo and redo

Register `HistoryState`, wrap commands with `Record<S>`, and call `Undo<S>` /
`Redo<S>`:

```dart
await context.call(
  Record<CounterState>(
    const IncrementCounter(),
    debounce: const Duration(milliseconds: 400),
    groupKey: 'counter',
  ),
);
await context.call(const Undo<CounterState>());
```

See [doc/USAGE.md](doc/USAGE.md) for debounce grouping, `maxEntries`, and
memento merge behavior.

## Performance notes

- State updates are **versioned per type**; widgets that call `of<S>()` rebuild
  only when `S` changes, not when unrelated types change.
- Scope notifications are **coalesced per frame** (microtask batching).
- The inherited provider rebuilds through a lightweight host, not the full
  `AnyScope` configuration widget.
- Use **`read`** in event handlers to avoid unnecessary listenables.
- Use **`AnySelector`** when a widget depends on a slice of a large state object.

## Logging

Debug builds log scope layout and command results under `any.scope` via
`dart:developer`. Logs include command types, scope version, and affected state
types—not state payloads.

## Public API

Exported from `package:any/any.dart`:

`AnyScope`, `AnySelector`, `Binding`, `RepositoryBinding`, `Command`,
`CommandContext`, `InitContext`, `ScopeMemento`, `HistoryState`, `Record`,
`Undo`, `Redo`, `StatesBuilder`, `Updater`, and `AnyScopeBuildContext`.