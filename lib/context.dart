part of 'any.dart';

/// Access to the nearest [AnyScope] from a [BuildContext].
extension AnyScopeBuildContext on BuildContext {
  /// Reads and subscribes to state [S]; the widget rebuilds when [S] changes.
  S of<S>() => _AnyProvider.of<S>(this);

  /// Reads state [S] once without subscribing to later updates.
  S read<S>() => _AnyProvider.read<S>(this);

  /// Like [of], but returns `null` when no [AnyScope] ancestor exists.
  S? maybeOf<S>() => _AnyProvider.maybeOf<S>(this);

  /// Runs a [Command] on the nearest scope.
  Future<void> call(Command command) => _AnyProvider.call(this, command);
}