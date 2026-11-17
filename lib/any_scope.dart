part of 'any.dart';

/// Root widget that holds application state and repositories.
class AnyScope extends StatefulWidget {
  const AnyScope({
    super.key,
    required this.states,
    required this.child,
    this.repositories = const [],
  });

  final StatesBuilder states;
  final List<RepositoryBinding> repositories;
  final Widget child;

  @override
  State<AnyScope> createState() => _AnyScopeState();
}

class _AnyScopeState extends State<AnyScope> {
  late final _Scope _scope;

  @override
  void initState() {
    super.initState();
    _scope = _Scope(
      states: widget.states,
      repositories: widget.repositories,
    );
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnyScopeHost(
      scope: _scope,
      child: widget.child,
    );
  }
}

/// Rebuilds only the [InheritedModel] host when [scope] notifies, not [AnyScope].
class _AnyScopeHost extends StatefulWidget {
  const _AnyScopeHost({
    required this.scope,
    required this.child,
  });

  final _Scope scope;
  final Widget child;

  @override
  State<_AnyScopeHost> createState() => _AnyScopeHostState();
}

class _AnyScopeHostState extends State<_AnyScopeHost> {
  @override
  void initState() {
    super.initState();
    widget.scope.addListener(_onScopeChanged);
  }

  @override
  void didUpdateWidget(covariant _AnyScopeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scope, widget.scope)) {
      oldWidget.scope.removeListener(_onScopeChanged);
      widget.scope.addListener(_onScopeChanged);
    }
  }

  @override
  void dispose() {
    widget.scope.removeListener(_onScopeChanged);
    super.dispose();
  }

  void _onScopeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _AnyProvider(
      scope: widget.scope,
      snapshot: widget.scope.snapshot,
      child: widget.child,
    );
  }
}

class _AnyProvider extends InheritedModel<Object> {
  const _AnyProvider({
    required this.scope,
    required this.snapshot,
    required super.child,
  });

  final _Scope scope;
  final _ScopeSnapshot snapshot;

  static S of<S>(BuildContext context) {
    final provider = InheritedModel.inheritFrom<_AnyProvider>(
      context,
      aspect: _StateAspect<S>(),
    );
    if (provider == null) {
      throw FlutterError('No AnyScope found above this BuildContext.');
    }
    return provider.snapshot.read<S>();
  }

  static S? maybeOf<S>(BuildContext context) {
    final provider = InheritedModel.inheritFrom<_AnyProvider>(
      context,
      aspect: _StateAspect<S>(),
    );
    return provider?.snapshot.read<S>();
  }

  static S read<S>(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<_AnyProvider>();
    if (provider == null) {
      throw FlutterError('No AnyScope found above this BuildContext.');
    }
    return provider.snapshot.read<S>();
  }

  static Future<void> call(BuildContext context, Command command) =>
      _provider(context).scope.call(command);

  static _AnyProvider _provider(BuildContext context) {
    final provider = context.getInheritedWidgetOfExactType<_AnyProvider>();
    if (provider == null) {
      throw FlutterError('No AnyScope found above this BuildContext.');
    }
    return provider;
  }

  @override
  bool updateShouldNotify(covariant _AnyProvider oldWidget) =>
      snapshot.version != oldWidget.snapshot.version;

  @override
  bool updateShouldNotifyDependent(
    covariant _AnyProvider oldWidget,
    Set<Object> dependencies,
  ) => dependencies.whereType<_StateDependency>().any(
    (dependency) => dependency.changed(oldWidget.snapshot, snapshot),
  );
}

abstract class _StateDependency {
  bool changed(_ScopeSnapshot oldSnapshot, _ScopeSnapshot newSnapshot);
}

class _StateAspect<S> implements _StateDependency {
  const _StateAspect();

  @override
  bool changed(_ScopeSnapshot oldSnapshot, _ScopeSnapshot newSnapshot) =>
      oldSnapshot.versionOf<S>() != newSnapshot.versionOf<S>();

  @override
  bool operator ==(Object other) => other is _StateAspect<S>;

  @override
  int get hashCode => S.hashCode;
}
