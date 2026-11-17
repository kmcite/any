import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('read does not subscribe and avoids extra rebuilds', (tester) async {
    final buildCounts = _BuildCounts();

    await tester.pumpWidget(
      AnyScope(
        states: (_) => [
          const _CounterState(0),
          const _LabelState('initial'),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _CounterView(buildCounts: buildCounts),
                _LabelView(buildCounts: buildCounts),
                Builder(
                  builder: (context) => ElevatedButton(
                    key: const ValueKey('read-label'),
                    onPressed: () {
                      context.read<_LabelState>();
                    },
                    child: const Text('Read label'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(buildCounts.counter, 1);
    expect(buildCounts.label, 1);

    await tester.tap(find.byKey(const ValueKey('read-label')));
    await tester.pump();

    expect(buildCounts.counter, 1);
    expect(buildCounts.label, 1);

    await tester.tap(find.byKey(const ValueKey('increment-counter')));
    await tester.pumpAndSettle();

    expect(buildCounts.counter, 2);
    expect(buildCounts.label, 1);
  });

  testWidgets('AnySelector rebuilds only when the selected value changes', (
    tester,
  ) async {
    final counterBuilds = ValueNotifier<int>(0);
    final labelBuilds = ValueNotifier<int>(0);

    await tester.pumpWidget(
      AnyScope(
        states: (_) => [
          const _CounterState(0),
          const _LabelState('initial'),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  _InstrumentedCounterSelector(counterBuilds: counterBuilds),
                  _InstrumentedLabelSelector(labelBuilds: labelBuilds),
                  ElevatedButton(
                    key: const ValueKey('increment-counter'),
                    onPressed: () => context.call(const _IncrementCounter()),
                    child: const Text('Increment'),
                  ),
                  ElevatedButton(
                    key: const ValueKey('change-label'),
                    onPressed: () => context.call(const _ChangeLabel()),
                    child: const Text('Change label'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(counterBuilds.value, 1);
    expect(labelBuilds.value, 1);

    await tester.tap(find.byKey(const ValueKey('increment-counter')));
    await tester.pumpAndSettle();

    expect(counterBuilds.value, 2);
    expect(labelBuilds.value, 1);

    await tester.tap(find.byKey(const ValueKey('change-label')));
    await tester.pumpAndSettle();

    expect(counterBuilds.value, 2);
    expect(labelBuilds.value, 2);
  });

  testWidgets('maybeOf returns null outside AnyScope and value inside', (
    tester,
  ) async {
    _CounterState? insideValue;
    late BuildContext outsideScope;

    await tester.pumpWidget(
      AnyScope(
        states: (_) => [const _CounterState(7)],
        child: Builder(
          builder: (context) {
            insideValue = context.maybeOf<_CounterState>();
            return const SizedBox();
          },
        ),
      ),
    );

    expect(insideValue?.value, 7);

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          outsideScope = context;
          return const SizedBox();
        },
      ),
    );

    expect(outsideScope.maybeOf<_CounterState>(), isNull);
  });
}

class _CounterState {
  const _CounterState(this.value);

  final int value;
}

class _LabelState {
  const _LabelState(this.value);

  final String value;
}

class _BuildCounts {
  int counter = 0;
  int label = 0;
}

class _CounterView extends StatelessWidget {
  const _CounterView({required this.buildCounts});

  final _BuildCounts buildCounts;

  @override
  Widget build(BuildContext context) {
    buildCounts.counter++;
    return ElevatedButton(
      key: const ValueKey('increment-counter'),
      onPressed: () => context.call(const _IncrementCounter()),
      child: Text('counter:${context.of<_CounterState>().value}'),
    );
  }
}

class _LabelView extends StatelessWidget {
  const _LabelView({required this.buildCounts});

  final _BuildCounts buildCounts;

  @override
  Widget build(BuildContext context) {
    buildCounts.label++;
    return ElevatedButton(
      key: const ValueKey('change-label'),
      onPressed: () => context.call(const _ChangeLabel()),
      child: Text('label:${context.of<_LabelState>().value}'),
    );
  }
}

class _InstrumentedCounterSelector extends StatelessWidget {
  const _InstrumentedCounterSelector({required this.counterBuilds});

  final ValueNotifier<int> counterBuilds;

  @override
  Widget build(BuildContext context) {
    return AnySelector<_CounterState, int>(
      selector: (state) => state.value,
      builder: (context, value) {
        counterBuilds.value++;
        return Text('counter:$value');
      },
    );
  }
}

class _InstrumentedLabelSelector extends StatelessWidget {
  const _InstrumentedLabelSelector({required this.labelBuilds});

  final ValueNotifier<int> labelBuilds;

  @override
  Widget build(BuildContext context) {
    return AnySelector<_LabelState, String>(
      selector: (state) => state.value,
      builder: (context, value) {
        labelBuilds.value++;
        return Text('label:$value');
      },
    );
  }
}

class _IncrementCounter extends Command {
  const _IncrementCounter();

  @override
  void call(CommandContext context) {
    context.call<_CounterState>(
      (state) => _CounterState(state.value + 1),
    );
  }
}

class _ChangeLabel extends Command {
  const _ChangeLabel();

  @override
  void call(CommandContext context) {
    context.call<_LabelState>((_) => const _LabelState('changed'));
  }
}