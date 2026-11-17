import 'package:any/any.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('Scope runtime', () {
    testWidgets('states builder runs once and can read InitRef repos', (
      tester,
    ) async {
      var builderCalls = 0;
      const repository = CounterRepository(7);

      await tester.pumpWidget(
        AnyScope(
          repositories: [Binding(repository)],
          states: (initRef) {
            builderCalls++;
            return [CounterState(initRef.get<CounterRepository>().initialCount)];
          },
          child: Builder(
            builder: (context) => Text(
              'counter:${context.of<CounterState>().value}',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );

      expect(find.text('counter:7'), findsOneWidget);
      expect(builderCalls, 1);
    });

    testWidgets('lazy repositories stay unevaluated until get', (
      tester,
    ) async {
      var creations = 0;
      late BuildContext context;

      await tester.pumpWidget(
        AnyScope(
          repositories: [
            Binding<CounterRepository>.lazy(() {
              creations++;
              return const CounterRepository(3);
            }),
          ],
          states: (_) => [const CounterState(0)],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(creations, 0);
      await context.call(const AddRepositoryValue());
      expect(creations, 1);
      await context.call(const AddRepositoryValue());
      expect(creations, 1);
      await tester.pump();
      expect(context.of<CounterState>().value, 6);
    });

    testWidgets('rejects duplicate state types', (tester) async {
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [0, 1],
          child: const SizedBox(),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('rejects duplicate repository types', (tester) async {
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [0],
          repositories: [
            Binding(const CounterRepository(1)),
            Binding(const CounterRepository(2)),
          ],
          child: const SizedBox(),
        ),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('of throws StateError for an unregistered state type', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0)],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(() => context.of<LabelState>(), throwsA(isA<StateError>()));
    });

    testWidgets('replacement and same-instance commits both notify', (
      tester,
    ) async {
      final builds = BuildCounts();
      late BuildContext context;

      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0), MutableFlag()],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              builds.counter++;
              final counter = context.of<CounterState>().value;
              final dark = context.of<MutableFlag>().isDark;
              return Text(
                'counter:$counter dark:$dark',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(builds.counter, 1);
      expect(find.text('counter:0 dark:false'), findsOneWidget);

      await context.call(const KeepCounter());
      await tester.pumpAndSettle();
      expect(builds.counter, 2);

      await context.call(const ToggleMutableFlag());
      await tester.pumpAndSettle();
      expect(find.text('counter:0 dark:true'), findsOneWidget);
      expect(builds.counter, 3);

      await context.call(const IncrementCounter());
      await tester.pumpAndSettle();
      expect(find.text('counter:1 dark:true'), findsOneWidget);
      expect(builds.counter, 4);
    });

    testWidgets('multiple updates in one command coalesce to one rebuild', (
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
              final counter = context.of<CounterState>().value;
              final label = context.of<LabelState>().value;
              return Text(
                '$counter:$label',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(builds, 1);

      await context.call(const ChangeBoth());
      await tester.pumpAndSettle();

      expect(find.text('1:changed'), findsOneWidget);
      expect(builds, 2);
    });

    testWidgets('disposed scope does not notify after late microtasks', (
      tester,
    ) async {
      var builds = 0;
      late BuildContext context;

      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0)],
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

      final pending = context.call(const IncrementCounter());
      await tester.pumpWidget(const SizedBox());
      await pending;
      await tester.pumpAndSettle();

      expect(builds, 1);
    });
  });
}
