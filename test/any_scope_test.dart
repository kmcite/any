import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('AnyScope', () {
    testWidgets('exposes initial state to dependents', (tester) async {
      await tester.pumpWidget(
        scopeApp(
          states: (_) => [const CounterState(5), const LabelState('hi')],
          child: Builder(
            builder: (context) => Column(
              children: [
                Text('counter:${context.of<CounterState>().value}'),
                Text('label:${context.of<LabelState>().value}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('counter:5'), findsOneWidget);
      expect(find.text('label:hi'), findsOneWidget);
    });

    testWidgets('notifies only widgets that subscribed to a changed type', (
      tester,
    ) async {
      final builds = BuildCounts();

      await tester.pumpWidget(
        scopeApp(
          states: (_) => [const CounterState(0), const LabelState()],
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  builds.counter++;
                  return Text('counter:${context.of<CounterState>().value}');
                },
              ),
              Builder(
                builder: (context) {
                  builds.label++;
                  return Text('label:${context.of<LabelState>().value}');
                },
              ),
              Builder(
                builder: (context) => ElevatedButton(
                  key: const ValueKey('increment'),
                  onPressed: () => context.call(const IncrementCounter()),
                  child: const Text('Increment'),
                ),
              ),
              Builder(
                builder: (context) => ElevatedButton(
                  key: const ValueKey('label'),
                  onPressed: () => context.call(const ChangeLabel()),
                  child: const Text('Label'),
                ),
              ),
            ],
          ),
        ),
      );

      expect(builds.counter, 1);
      expect(builds.label, 1);

      await tapKey(tester, 'increment');
      expect(find.text('counter:1'), findsOneWidget);
      expect(builds.counter, 2);
      expect(builds.label, 1);

      await tapKey(tester, 'label');
      expect(find.text('label:changed'), findsOneWidget);
      expect(builds.counter, 2);
      expect(builds.label, 2);
    });

    testWidgets('host rebuilds children without recreating states builder', (
      tester,
    ) async {
      var builderCalls = 0;
      late BuildContext context;

      await tester.pumpWidget(
        AnyScope(
          states: (_) {
            builderCalls++;
            return [const CounterState(0)];
          },
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return Text(
                '${context.of<CounterState>().value}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(builderCalls, 1);
      await context.call(const IncrementCounter());
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(builderCalls, 1);
    });

    testWidgets('replacing AnyScope with a new key rebuilds a fresh scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        AnyScope(
          key: const ValueKey('a'),
          states: (_) => [const CounterState(1)],
          child: Builder(
            builder: (context) => Text(
              '${context.of<CounterState>().value}',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(
        AnyScope(
          key: const ValueKey('b'),
          states: (_) => [const CounterState(9)],
          child: Builder(
            builder: (context) => Text(
              '${context.of<CounterState>().value}',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );
      expect(find.text('9'), findsOneWidget);
    });
  });
}
