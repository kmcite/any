part of 'any.dart';

class _Scope extends ChangeNotifier {
  _Scope({
    required StatesBuilder states,
    Iterable<RepositoryBinding> repositories = const [],
  }) : _repositories = _indexBindings(repositories) {
    _states.addAll(_indexStates(states(_InitRef(this))));
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

  Future<void> call(Command command) async {
    final ref = _Ref(this);
    final label = command.runtimeType;
    try {
      await command.call(ref);

      _log(
        '$label '
        '(v: $_version, '
        'affected: [${ref.changedAspects.join(', ')}])',
      );
    } catch (error, stackTrace) {
      _log(
        'Command failed: $label '
        '(v: $_version, '
        'affected: [${ref.changedAspects.join(', ')}])',
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

    // Always bump the version. Returning the same instance is the normal
    // path for mutable models updated in place; skipping would silence UI.
    if (!identical(_states[S], state)) {
      _states[S] = state as Object;
    }

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

class _InitRef implements InitRef {
  const _InitRef(this._scope);

  final _Scope _scope;

  @override
  R get<R>() => _scope.getRepository<R>();
}

class _Ref implements Ref {
  _Ref(this._scope);

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
}

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
