import 'package:any/any.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  group('Command / Ref', () {
    testWidgets('sync command reads state and repositories then commits', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        AnyScope(
          repositories: [Binding(const CounterRepository(4))],
          states: (initRef) => [
            CounterState(initRef.get<CounterRepository>().initialCount),
          ],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(context.of<CounterState>().value, 4);

      await context.call(const AddRepositoryValue());
      await tester.pump();

      expect(context.of<CounterState>().value, 8);
    });

    testWidgets('async commands complete before callers continue', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0)],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return Text(
                'counter:${context.of<CounterState>().value}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('counter:0'), findsOneWidget);

      final future = context.call(const AsyncIncrementCounter());
      expect(find.text('counter:0'), findsOneWidget);

      await future;
      await tester.pumpAndSettle();
      expect(find.text('counter:1'), findsOneWidget);
    });

    testWidgets('command errors are rethrown and leave state unchanged', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(0), const LabelState('safe')],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      await expectLater(
        context.call(const ThrowCommand()),
        throwsA(isA<ArgumentError>()),
      );
      await tester.pump();
      expect(context.of<CounterState>().value, 0);
      expect(context.of<LabelState>().value, 'safe');
    });

    testWidgets('missing state and repository lookups throw StateError', (
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

      await expectLater(
        context.call(const ReadMissingState()),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        context.call(const ReadMissingRepository()),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        context.call(const UpdateUnregisteredState()),
        throwsA(isA<StateError>()),
      );
    });

    testWidgets('Ref.call works via the call tear-off syntax', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        AnyScope(
          states: (_) => [const CounterState(1)],
          child: Builder(
            builder: (buildContext) {
              context = buildContext;
              return Text(
                'counter:${context.of<CounterState>().value}',
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      await context.call(const _CallTearOffIncrement());
      await tester.pumpAndSettle();
      expect(find.text('counter:2'), findsOneWidget);
    });

  });
}

class _CallTearOffIncrement extends Command {
  const _CallTearOffIncrement();

  @override
  void call(Ref ref) {
    ref.call<CounterState>((state) => state.copyWith(value: state.value + 1));
  }
}
