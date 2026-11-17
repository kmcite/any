import 'package:any/any.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('AnyScopeBuildContext', () {
    testWidgets('of subscribes and rebuilds when that state changes', (
      tester,
    ) async {
      var builds = 0;
      late BuildContext context;

      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0), const LabelState()],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              builds++;
              return Text(
                '${context.of<CounterState>().value}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(builds, 1);
      await context.call(const IncrementCounter());
      await tester.pumpAndSettle();
      expect(builds, 2);

      await context.call(const ChangeLabel());
      await tester.pumpAndSettle();
      expect(builds, 2);
    });

    testWidgets('read does not subscribe to later updates', (tester) async {
      var builds = 0;
      late BuildContext context;

      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0)],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              builds++;
              final value = context.read<CounterState>().value;
              return Text('$value', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(builds, 1);
      expect(find.text('0'), findsOneWidget);

      await context.call(const IncrementCounter());
      await tester.pumpAndSettle();
      expect(builds, 1);
      expect(find.text('0'), findsOneWidget);
      expect(context.read<CounterState>().value, 1);
    });

    testWidgets('maybeOf returns value inside scope and null outside', (
      tester,
    ) async {
      CounterState? inside;

      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(7)],
          child: Builder(
            builder: (context) {
              inside = context.maybeOf<CounterState>();
              return const SizedBox();
            },
          ),
        ),
      );
      expect(inside?.value, 7);

      late BuildContext outside;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            outside = context;
            return const SizedBox();
          },
        ),
      );
      expect(outside.maybeOf<CounterState>(), isNull);
    });

    testWidgets('of, read, and call throw outside AnyScope', (tester) async {
      late BuildContext outside;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            outside = context;
            return const SizedBox();
          },
        ),
      );

      expect(() => outside.of<CounterState>(), throwsA(isA<FlutterError>()));
      expect(() => outside.read<CounterState>(), throwsA(isA<FlutterError>()));
      expect(
        () => outside.call(const IncrementCounter()),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('call dispatches commands on the nearest scope', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(2)],
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

      await context.call(const IncrementCounter(3));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
    });
  });
}
