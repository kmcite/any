import 'dart:async' show FutureOr, scheduleMicrotask;
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

typedef Updater<S> = S Function(S state);
typedef StatesBuilder = List<Object> Function(InitContext context);

// ============================================================
// Dependency Binding
// ============================================================

abstract interface class RepositoryBinding {
  Type get type;

  Object get instance;

  bool get isLazy;
}

class Binding<R extends Object> implements RepositoryBinding {
  Binding(R instance) : type = R, _create = null, _instance = instance;

  Binding.lazy(R Function() create) : type = R, _create = create;

  @override
  final Type type;
  final R Function()? _create;
  R? _instance;

  @override
  R get instance => _instance ??= _create!();

  @override
  bool get isLazy => _create != null;
}

// ============================================================
// Memento (State Checkpoint)
// ============================================================

class ScopeMemento {
  ScopeMemento._(Map<Type, Object> states) : _states = Map.unmodifiable(states);

  final Map<Type, Object> _states;

  S read<S>() {
    final state = _states[S];
    if (state == null) {
      throw StateError('State $S was not captured in this ScopeMemento.');
    }
    return state as S;
  }

  bool has<S>() => _states.containsKey(S);

  ScopeMemento merge(ScopeMemento other) =>
      ScopeMemento._({..._states, ...other._states});
}

// ============================================================
// Contexts & Command
// ============================================================

abstract interface class InitContext {
  R get<R>();
}

abstract interface class CommandContext {
  S of<S>();

  R get<R>();

  void call<S>(Updater<S> updater);

  ScopeMemento save();

  ScopeMemento saveOnly<S>();

  void restore(ScopeMemento memento);
}

abstract class const Command() {
  FutureOr<void> call(CommandContext f);
}

// ============================================================
// Undo / Redo History Extension
// ============================================================

final class HistoryState {
  const HistoryState({
    this.past = const [],
    this.future = const [],
    this.maxEntries = 30,
    this.lastRecordedAt,
    this.lastGroupKey,
  });

  final List<ScopeMemento> past;
  final List<ScopeMemento> future;
  final int maxEntries;
  final DateTime? lastRecordedAt;
  final Object? lastGroupKey;

  bool get canUndo => past.isNotEmpty;
  bool get canRedo => future.isNotEmpty;

  HistoryState push(
    ScopeMemento snapshot, {
    DateTime? timestamp,
    Object? groupKey,
  }) {
    final nextPast = [...past, snapshot];
    if (nextPast.length > maxEntries) {
      nextPast.removeAt(0);
    }
    return HistoryState(
      past: List.unmodifiable(nextPast),
      future: const [],
      maxEntries: maxEntries,
      lastRecordedAt: timestamp,
      lastGroupKey: groupKey,
    );
  }

  HistoryState extendBurst(DateTime timestamp, Object? groupKey) {
    return HistoryState(
      past: past,
      future: future,
      maxEntries: maxEntries,
      lastRecordedAt: timestamp,
      lastGroupKey: groupKey,
    );
  }
}

class Record<S> extends Command {
  const Record(
    this.command, {
    this.debounce,
    this.groupKey,
  });

  final Command command;
  final Duration? debounce;
  final Object? groupKey;

  @override
  Future<void> call(CommandContext f) async {
    final before = f.saveOnly<S>();

    await command(f);

    if (identical(before.read<S>(), f.of<S>())) return;

    final now = DateTime.now();
    final history = f.of<HistoryState>();

    final withinWindow =
        debounce != null &&
        history.lastRecordedAt != null &&
        history.lastGroupKey == groupKey &&
        now.difference(history.lastRecordedAt!) < debounce!;

    if (withinWindow) {
      f<HistoryState>((h) => h.extendBurst(now, groupKey));
    } else {
      f<HistoryState>(
        (h) => h.push(before, timestamp: now, groupKey: groupKey),
      );
    }
  }
}

class Undo<S> extends Command {
  const Undo();

  @override
  void call(CommandContext f) {
    final history = f.of<HistoryState>();
    if (!history.canUndo) return;

    final current = f.saveOnly<S>();
    final previous = history.past.last;

    f.restore(previous);
    f<HistoryState>(
      (h) => HistoryState(
        past: List.unmodifiable(h.past.sublist(0, h.past.length - 1)),
        future: List.unmodifiable([current, ...h.future]),
        maxEntries: h.maxEntries,
      ),
    );
  }
}

class Redo<S> extends Command {
  const Redo();

  @override
  void call(CommandContext f) {
    final history = f.of<HistoryState>();
    if (!history.canRedo) return;

    final current = f.saveOnly<S>();
    final next = history.future.first;

    f.restore(next);
    f<HistoryState>(
      (h) => HistoryState(
        past: List.unmodifiable([...h.past, current]),
        future: List.unmodifiable(h.future.sublist(1)),
        maxEntries: h.maxEntries,
      ),
    );
  }
}

// ============================================================
// Scope
// ============================================================

class _Scope extends ChangeNotifier {
  _Scope({
    required StatesBuilder states,
    Iterable<RepositoryBinding> repositories = const [],
  }) : _repositories = _indexBindings(repositories) {
    _states.addAll(_indexStates(states(_InitContext(this))));
    _stateVersions = {for (final type in _states.keys) type: 0};
    final stateTypes = _states.keys.toList(growable: false);
    _log(
      [
        'Scope #${identityHashCode(this)}',
        '├── Repositories (${_repositories.length})',
        ..._repositoryTreeEntries(_repositories, '│   '),
        '└── States (${stateTypes.length})',
        ..._treeEntries(stateTypes, '    '),
      ].join('\n'),
    );
  }

  final Map<Type, Object> _states = {};
  final Map<Type, RepositoryBinding> _repositories;
  late final Map<Type, int> _stateVersions;

  _ScopeSnapshot? _snapshotCache;
  int _version = 0;
  bool _notificationScheduled = false;
  bool _disposed = false;

  _ScopeSnapshot get snapshot => _snapshotCache ??= _ScopeSnapshot(
    states: Map.unmodifiable(_states),
    stateVersions: Map.unmodifiable(_stateVersions),
    version: _version,
  );

  S getState<S>() {
    final state = _states[S];
    if (state == null) {
      throw StateError('No state registered for type $S.');
    }
    return state as S;
  }

  R getRepository<R>() {
    final binding = _repositories[R];
    if (binding == null) {
      throw StateError('No repository registered for type $R.');
    }
    return binding.instance as R;
  }

  ScopeMemento saveAll() => ScopeMemento._(_states);

  ScopeMemento saveOnly<S>() {
    final state = getState<S>();
    return ScopeMemento._({S: state as Object});
  }

  Set<Type> restore(ScopeMemento memento) {
    for (final type in memento._states.keys) {
      if (!_states.containsKey(type)) {
        throw StateError('Cannot restore unregistered state type $type.');
      }
    }

    final restoredTypes = <Type>{};

    for (final entry in memento._states.entries) {
      final type = entry.key;
      final savedState = entry.value;

      if (!identical(_states[type], savedState)) {
        _states[type] = savedState;
        _stateVersions[type] = _stateVersions[type]! + 1;
        restoredTypes.add(type);
      }
    }

    if (restoredTypes.isNotEmpty) {
      _version += 1;
      _snapshotCache = null;
      _scheduleNotification();
    }

    return restoredTypes;
  }

  Future<void> call(Command command) async {
    final context = _CommandContext(this);
    try {
      await command(context);

      _log(
        '${command.runtimeType} '
        '(v: $_version, '
        'affected: [${context.changedAspects.join(', ')}])',
      );
    } catch (error, stackTrace) {
      _log(
        'Command failed: ${command.runtimeType} '
        '(v: $_version, '
        'affected: [${context.changedAspects.join(', ')}])',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _commit<S>(S state) {
    if (!_states.containsKey(S)) {
      throw StateError('No state registered for type $S.');
    }

    if (identical(_states[S], state)) return false;

    _states[S] = state as Object;
    _stateVersions[S] = _stateVersions[S]! + 1;
    _version += 1;
    _snapshotCache = null;
    _scheduleNotification();
    return true;
  }

  bool updateState<S>(Updater<S> updater) {
    return _commit<S>(updater(getState<S>()));
  }

  void _scheduleNotification() {
    if (_notificationScheduled) return;
    _notificationScheduled = true;

    scheduleMicrotask(() {
      _notificationScheduled = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// ============================================================
// Snapshot & Context Implementations
// ============================================================

class _ScopeSnapshot {
  const _ScopeSnapshot({
    required this.states,
    required this.stateVersions,
    required this.version,
  });

  final Map<Type, Object> states;
  final Map<Type, int> stateVersions;
  final int version;

  S read<S>() {
    final state = states[S];
    if (state == null) {
      throw StateError('No state registered for type $S.');
    }
    return state as S;
  }

  int versionOf<S>() {
    final stateVersion = stateVersions[S];
    if (stateVersion == null) {
      throw StateError('No state registered for type $S.');
    }
    return stateVersion;
  }
}

class _InitContext implements InitContext {
  const _InitContext(this._scope);

  final _Scope _scope;

  @override
  R get<R>() => _scope.getRepository<R>();
}

class _CommandContext implements CommandContext {
  _CommandContext(this._scope);

  final _Scope _scope;
  final Set<Type> changedAspects = {};

  @override
  S of<S>() => _scope.getState<S>();

  @override
  R get<R>() => _scope.getRepository<R>();

  @override
  void call<S>(Updater<S> updater) {
    if (_scope.updateState<S>(updater)) {
      changedAspects.add(S);
    }
  }

  @override
  ScopeMemento save() => _scope.saveAll();

  @override
  ScopeMemento saveOnly<S>() => _scope.saveOnly<S>();

  @override
  void restore(ScopeMemento memento) {
    changedAspects.addAll(_scope.restore(memento));
  }
}

// ============================================================
// Widget & InheritedModel
// ============================================================

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
    )..addListener(_onScopeChanged);
  }

  void _onScopeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scope
      ..removeListener(_onScopeChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AnyProvider(
      scope: _scope,
      snapshot: _scope.snapshot,
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

  static Future<void> call(BuildContext context, Command command) =>
      _provider(context).scope.call(command);

  static ScopeMemento save(BuildContext context) =>
      _provider(context).scope.saveAll();

  static ScopeMemento saveOnly<S>(BuildContext context) =>
      _provider(context).scope.saveOnly<S>();

  static void restore(BuildContext context, ScopeMemento memento) =>
      _provider(context).scope.restore(memento);

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

// ============================================================
// BuildContext API
// ============================================================

extension AnyScopeBuildContext on BuildContext {
  S of<S>() => _AnyProvider.of<S>(this);

  Future<void> call(Command command) => _AnyProvider.call(this, command);

  ScopeMemento save() => _AnyProvider.save(this);

  ScopeMemento saveOnly<S>() => _AnyProvider.saveOnly<S>(this);

  void restore(ScopeMemento memento) => _AnyProvider.restore(this, memento);
}

// ============================================================
// Helpers & Logging
// ============================================================

Map<Type, Object> _indexStates(Iterable<Object> states) {
  final indexed = <Type, Object>{};
  for (final state in states) {
    final type = state.runtimeType;
    if (indexed.containsKey(type)) {
      throw ArgumentError('Only one state of type $type can be registered.');
    }
    indexed[type] = state;
  }
  return indexed;
}

Map<Type, RepositoryBinding> _indexBindings(
  Iterable<RepositoryBinding> bindings,
) {
  final indexed = <Type, RepositoryBinding>{};
  for (final binding in bindings) {
    final type = binding.type;
    if (indexed.containsKey(type)) {
      throw ArgumentError(
        'Only one repository of type $type can be registered.',
      );
    }
    indexed[type] = binding;
  }
  return indexed;
}

List<String> _repositoryTreeEntries(
  Map<Type, RepositoryBinding> repositories,
  String indent,
) {
  final entries = repositories.entries.toList(growable: false);
  return [
    for (var index = 0; index < entries.length; index++)
      '$indent${index == entries.length - 1 ? '└──' : '├──'} '
          '[${entries[index].value.isLazy ? 'L' : 'R'}] ${entries[index].key}',
  ];
}

void _log(String message, {Object? error, StackTrace? stackTrace}) {
  if (!kDebugMode) return;
  developer.log(
    '$message\n',
    name: 'any.scope',
    error: error,
    stackTrace: stackTrace,
  );
}

List<String> _treeEntries(List<Type> types, String indent) => [
  for (var index = 0; index < types.length; index++)
    '$indent${index == types.length - 1 ? '└──' : '├──'} ${types[index]}',
];
