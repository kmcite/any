part of 'any.dart';

/// Transforms the current value of state [S] into its next value.
typedef Updater<S> = S Function(S state);

/// Builds the initial state objects for an [AnyScope].
typedef StatesBuilder = List<Object> Function(InitRef initRef);

/// Repository lookup available while building the initial state list.
abstract interface class InitRef {
  R get<R>();
}

/// Read and update handle passed to [Command.call].
abstract interface class Ref {
  S of<S>();

  R get<R>();

  /// Commits an update for [S] and notifies subscribers.
  ///
  /// Always bumps the version for [S], even when [updater] returns the same
  /// instance. That makes in-place mutation of mutable models reactive:
  /// `ref.call<ThemePreference>((t) => t..dark = !t.dark)`.
  void call<S>(Updater<S> updater);
}

/// Named unit of work that reads repositories and commits state.
abstract class const Command() {
  FutureOr<void> call(Ref ref);
}
