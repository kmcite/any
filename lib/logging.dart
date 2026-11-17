part of 'any.dart';

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
