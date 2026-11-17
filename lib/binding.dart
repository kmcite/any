part of 'any.dart';

/// Resolves a repository instance for injection into [AnyScope].
abstract interface class RepositoryBinding {
  Type get type;

  Object get instance;

  bool get isLazy;
}

/// Eager or lazy registration of a repository [R].
class Binding<R extends Object> implements RepositoryBinding {
  /// Creates an eager binding with a ready-to-use [instance].
  Binding(R instance) : type = R, _create = null, _instance = instance;

  /// Creates a lazy binding that calls [create] on the first [get] lookup.
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
