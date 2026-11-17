part of 'any.dart';

/// Rebuilds only when [selector] produces a new value for state [S].
class AnySelector<S, R> extends StatefulWidget {
  const AnySelector({
    super.key,
    required this.selector,
    required this.builder,
  });

  final R Function(S state) selector;
  final Widget Function(BuildContext context, R value) builder;

  @override
  State<AnySelector<S, R>> createState() => _AnySelectorState<S, R>();
}

class _AnySelectorState<S, R> extends State<AnySelector<S, R>> {
  R? _cachedValue;
  Widget? _cachedChild;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selector(context.of<S>());
    if (_cachedValue == selected && _cachedChild != null) {
      return _cachedChild!;
    }

    _cachedValue = selected;
    return _cachedChild = widget.builder(context, selected);
  }
}
