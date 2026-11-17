# any

`any` is a lean state-management solution for Flutter. Its goal is to make the
main application flow easy to understand:

1. **`AnyScope` holds the application's states and repositories.**
2. **Commands perform work and update state.** A command can read or update
   any registered state and access repositories through its command context.
3. **Widgets read and subscribe to state through `BuildContext`.**

The scope is the container, commands are the state-change path, and the UI
renders the resulting state.

## Installation

Add the GitHub repository as a dependency:

```yaml
dependencies:
  any:
    git:
      url: https://github.com/kmcite/any.git
```

Then run:

```sh
flutter pub get
```

## Quick start

The example below registers a state and repository, increments the state with
a command, and displays the current value in a widget.

```dart
import 'package:any/utils/any.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    AnyScope(
      states: (context) => [
        CounterState(
          count: context.get<CounterRepository>().initialCount,
        ),
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
  @override
  void call(CommandContext context) {
    final current = context.of<CounterState>().count;
    final next = context.get<CounterRepository>().nextCount(current);

    context.call<CounterState>(
      (state) => state.copyWith(count: next),
    );
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
        onPressed: () async {
          await context.call(IncrementCounter());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## The three pieces

### 1. `AnyScope`: application container

Place an `AnyScope` above the widgets that need access to the application:

```dart
AnyScope(
  states: (context) => [
    CounterState(
      count: context.get<CounterRepository>().initialCount,
    ),
  ],
  repositories: [Binding(CounterRepository())],
  child: const MyApp(),
)
```

The `states` callback receives an `InitContext` after repository bindings are
registered and returns the initial state objects. It runs once when the scope
is created. `InitContext` only provides `get<R>()`, so it can resolve
repositories without reading or modifying state. State objects are keyed by
their concrete runtime type. Repositories are registered through `Binding<R>`,
keyed by repository type. `Binding(repository)` provides an eager instance;
use `Binding.lazy(() => Repository())` to create and cache the instance on
first lookup. Register at most one state or repository binding of each type
in a scope; duplicate types throw an `ArgumentError`.

### 2. Commands: work and state changes

Extend the non-generic `Command` class. Its `call` method receives a
non-generic `CommandContext` and can return either `void` or a `Future<void>`:

- `context.of<S>()` reads the current state of type `S`.
- `context.get<R>()` retrieves a registered repository of type `R`.
- `context.call<S>(updater)` applies an updater to the current state of type
  `S`.

Commands can update any number of registered state types. Each call to
`context.call<S>(updater)` commits immediately, increments that state's
version, and notifies the scope. Keep updates predictable by returning new
state values rather than mutating existing ones.

### Mementos, undo, and redo

From a widget's `BuildContext`, capture state before an operation and restore
it later:

```dart
final checkpoint = context.saveOnly<CounterState>();
await context.call(IncrementCounter());
context.restore(checkpoint);
```

`context.save()` captures all registered states, while
`context.saveOnly<S>()` captures only state `S`. A memento supports `read<S>()`
and `has<S>()`; `merge(other)` combines mementos, with states from `other`
taking precedence when both contain the same type. Mementos hold state values,
not deep copies, so immutable state objects are recommended.

To enable command history, register a `HistoryState` with the other states:

```dart
states: (init) => [
  CounterState(count: init.get<CounterRepository>().initialCount),
  const HistoryState(),
],
```

Wrap state-changing commands in `Record<S>` and invoke `Undo<S>` or `Redo<S>`
through the widget context:

```dart
await context.call(
  Record<CounterState>(
    IncrementCounter(),
    debounce: const Duration(milliseconds: 400),
    groupKey: 'counter',
  ),
);
await context.call(const Undo<CounterState>());
await context.call(const Redo<CounterState>());
```

`Record<S>` stores a checkpoint for state `S` when the wrapped command changes
it; it does not record other state types the command may update. Updates with
the same `groupKey` inside the debounce window are combined into one undo step.
Without a debounce duration, each recorded change creates a separate step.
`HistoryState.canUndo` and `canRedo` can be used to enable or disable history
controls. It keeps up to 30 entries by default; configure `maxEntries` when
creating it to change that limit.

### 3. Widgets: read state and dispatch commands

Within an `AnyScope`, widgets use the `BuildContext` extensions:

```dart
final state = context.of<CounterState>();
await context.call(IncrementCounter());
```

`context.of<S>()` returns the current state and subscribes the calling widget
to updates of `S`. It rebuilds when that state changes, but not when an
unrelated state type changes. `context.call(command)` applies the command to
the scope above the current context.

Use these extensions below an `AnyScope`. State or repository lookups for
unregistered types throw a `StateError`; calling `context.call(command)`
without an `AnyScope` above the context throws a `FlutterError`.

## Logging

The library writes diagnostic log entries through `dart:developer` under the
`any.scope` log name. Scope creation lists repositories first, followed by
states. Repository entries are marked `[R]` for regular/eager bindings and
`[L]` for lazy bindings. Command success and failure messages are single-line
entries; successes include the command and version (`v`), while failures
attach error details. Command entries include the affected state types.
State and repository contents are not logged.

## Public API

Import the library with:

```dart
import 'package:any/utils/any.dart';
```

The public API includes `AnyScope`, `Binding`, `RepositoryBinding`,
`StatesBuilder`, `InitContext`, `CommandContext`, `ScopeMemento`,
`HistoryState`, `Record`, `Undo`, `Redo`, `Command`, `Updater`,
and the `BuildContext` extensions `of`, `call`, `save`, `saveOnly`, and
`restore`.
