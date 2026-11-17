# Example app

Demonstrates **any** with a small tasks UI: theme toggle, repository-backed
counter, command-driven CRUD, and selective rebuilds via `AnySelector`.

## Run

```sh
flutter pub get
flutter run
```

From the repository root you can also run:

```sh
flutter run -C example
```

## Structure

- `lib/main.dart` — `AnyScope` setup and `MaterialApp`
- `lib/commands/` — `Command` implementations
- `lib/states/` — immutable state types
- `lib/repositories/` — data access
- `lib/features/` — widgets

Import the library with `package:any/any.dart`, and example code with
`package:example/...`.