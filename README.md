# any

Lean command-based state management for Flutter: one scope, typed state,
repositories, and selective widget rebuilds.

| | |
|---|---|
| **Docs** | [Usage guide](doc/USAGE.md) · [Changelog](CHANGELOG.md) |
| **Demo** | [`example/`](example/) tasks app |
| **Import** | `package:any/any.dart` |

## Why any

1. **`AnyScope`** — register state and repositories once at the root.
2. **`Command`** — named units of work that read a **`Ref`** and commit updates.
3. **Widgets** — `context.of<S>()` (or `AnySelector`) subscribe only to the
   state types they need.

No codegen, no global singletons, and no rebuild of the whole tree when one
state type changes.

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

## Quick start

```dart
import 'package:any/any.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    AnyScope(
      states: (initRef) => [
        CounterState(count: initRef.get<CounterRepository>().initialCount),
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
  void call(Ref ref) {
    final current = ref.of<CounterState>().count;
    final next = ref.get<CounterRepository>().nextCount(current);
    ref.call<CounterState>((state) => state.copyWith(count: next));
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

## `Ref` vs `BuildContext`

| | **`Ref`** (inside `Command.call`) | **`BuildContext`** (widgets) |
|---|-----------------------------------|------------------------------|
| Read state | `ref.of<S>()` | `context.of<S>()` (subscribes) |
| Read once | — | `context.read<S>()` |
| Repository | `ref.get<R>()` | — (use a `Command`) |
| Commit state | `ref.call<S>(updater)` | — (use `context.call(command)`) |
| Run command | — | `context.call(command)` |

State commits always notify subscribers for that type, including in-place
mutation when the updater returns the same instance.

## Scope setup

```dart
AnyScope(
  states: (initRef) => [
    CounterState(count: initRef.get<CounterRepository>().initialCount),
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
- **`InitRef.get<R>()`** resolves repositories during initialization only.
- **`Binding(instance)`** is eager; **`Binding.lazy(() => …)`** creates on first
  `get`.

## Commands

```dart
context.call(const IncrementCounter());
```

Inside `Command.call(Ref ref)`:

| API | Purpose |
|-----|---------|
| `ref.of<S>()` | Current state |
| `ref.get<R>()` | Repository |
| `ref.call<S>(updater)` | Commit next value for `S` |

```dart
// Copy-on-write
ref.call<CounterState>((s) => s.copyWith(count: s.count + 1));

// Mutable model (same instance)
ref.call<ThemePreference>((t) => t..dark = !t.dark);
```

## Widget API

| Method | Subscribes? | Purpose |
|--------|-------------|---------|
| `context.of<S>()` | Yes | UI that tracks `S` |
| `context.read<S>()` | No | One-off read in callbacks |
| `context.maybeOf<S>()` | Yes | Like `of`, or `null` without a scope |
| `context.call(command)` | No | Run a `Command` |

### `AnySelector`

Rebuild only when `selector(state)` changes (`==`):

```dart
AnySelector<CounterState, int>(
  selector: (state) => state.count,
  builder: (context, count) => Text('$count'),
)
```

## Performance

- Per-type **versions** — `of<S>()` rebuilds only when `S` changes.
- Notifications **coalesced** per frame (microtask).
- Provider host rebuilds, not the full `AnyScope` config widget.
- Prefer **`read`** in handlers; use **`AnySelector`** for large state slices.

## Debugging

Debug builds log under `any.scope` (`dart:developer`): command type, scope
version, affected state types — not payloads.

## Library layout

| File | Role |
|------|------|
| `lib/any.dart` | Public library import |
| `lib/binding.dart` | `Binding`, `RepositoryBinding` |
| `lib/command.dart` | `Command`, `Ref`, `InitRef`, typedefs |
| `lib/scope.dart` | Scope runtime |
| `lib/any_scope.dart` | `AnyScope` + inherited provider |
| `lib/selector.dart` | `AnySelector` |
| `lib/context.dart` | `AnyScopeBuildContext` |
| `lib/logging.dart` | Debug tree / command logs |

Tests live beside each part: `test/binding_test.dart`, `test/command_test.dart`,
and so on.

## Public API

`AnyScope`, `AnySelector`, `AnyScopeBuildContext`, `Binding`, `RepositoryBinding`,
`Command`, `Ref`, `InitRef`, `StatesBuilder`, `Updater`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for breaking changes and migration notes.