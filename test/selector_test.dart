import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('AnySelector', () {
    testWidgets('rebuilds builder only when the selected value changes', (
      tester,
    ) async {
      final counterBuilds = ValueNotifier<int>(0);
      final labelBuilds = ValueNotifier<int>(0);
      late BuildContext context;

      await tester.pumpWidget(
        scopeApp(
          states: (_) => [const CounterState(0), const LabelState()],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return Column(
                children: [
                  AnySelector<CounterState, int>(
                    selector: (state) => state.value,
                    builder: (context, value) {
                      counterBuilds.value++;
                      return Text('counter:$value');
                    },
                  ),
                  AnySelector<LabelState, String>(
                    selector: (state) => state.value,
                    builder: (context, value) {
                      labelBuilds.value++;
                      return Text('label:$value');
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(counterBuilds.value, 1);
      expect(labelBuilds.value, 1);

      await context.call(const IncrementCounter());
      await tester.pumpAndSettle();
      expect(find.text('counter:1'), findsOneWidget);
      expect(counterBuilds.value, 2);
      expect(labelBuilds.value, 1);

      await context.call(const ChangeLabel('next'));
      await tester.pumpAndSettle();
      expect(find.text('label:next'), findsOneWidget);
      expect(counterBuilds.value, 2);
      expect(labelBuilds.value, 2);
    });

    testWidgets('skips builder when selected slice is unchanged by ==', (
      tester,
    ) async {
      var builderCalls = 0;
      late BuildContext context;

      await tester.pumpWidget(
        scopeApp(
          states: (_) => [const CounterState(0), const LabelState('keep')],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return AnySelector<LabelState, String>(
                selector: (state) => state.value,
                builder: (context, value) {
                  builderCalls++;
                  return Text('label:$value');
                },
              );
            },
          ),
        ),
      );

      expect(builderCalls, 1);

      // Counter changes, but this selector only watches LabelState.
      await context.call(const IncrementCounter());
      await tester.pumpAndSettle();
      expect(builderCalls, 1);

      // Label version bumps with an equal selected value.
      await context.call(const ChangeLabel('keep'));
      await tester.pumpAndSettle();
      expect(builderCalls, 1);
      expect(find.text('label:keep'), findsOneWidget);
    });
  });
}
