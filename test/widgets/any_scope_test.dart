import 'package:any/utils/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('initializes state from an eager repository once', (
    tester,
  ) async {
    final repository = _CounterRepository(7);
    var stateBuilderCalls = 0;

    await tester.pumpWidget(
      AnyScope(
        repositories: [Binding<_CounterRepository>(repository)],
        states: (init) {
          stateBuilderCalls++;
          return [
            _CounterState(init.get<_CounterRepository>().initialCount),
            const _LabelState('initial'),
          ];
        },
        child: const MaterialApp(
          home: Scaffold(body: _CounterDisplay()),
        ),
      ),
    );

    expect(find.text('counter:7'), findsOneWidget);
    expect(stateBuilderCalls, 1);
  });

  testWidgets('lazy repositories are created on demand and cached', (
    tester,
  ) async {
    var creations = 0;
    await tester.pumpWidget(
      AnyScope(
        repositories: [
          Binding<_CounterRepository>.lazy(() {
            creations++;
            return _CounterRepository(3);
          }),
        ],
        states: (_) => [const _CounterState(0), const _LabelState('initial')],
        child: MaterialApp(
          home: Scaffold(
            body: _CorePage(
              buildCounts: _BuildCounts(),
              onReadRepository: (context) =>
                  context.call(const _AddRepositoryValue()),
            ),
          ),
        ),
      ),
    );

    expect(creations, 0);
    await _tap(tester, 'read-repository');
    expect(creations, 1);
    expect(find.text('counter:3'), findsOneWidget);
  });

  testWidgets('commands update multiple states and notify only dependents', (
    tester,
  ) async {
    final buildCounts = _BuildCounts();
    await tester.pumpWidget(
      AnyScope(
        states: (_) => [const _CounterState(0), const _LabelState('initial')],
        child: MaterialApp(
          home: Scaffold(
            body: _CorePage(
              buildCounts: buildCounts,
              onReadRepository: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(buildCounts.counter, 1);
    expect(buildCounts.label, 1);

    await _tap(tester, 'keep-counter');
    expect(buildCounts.counter, 1);
    expect(buildCounts.label, 1);

    await _tap(tester, 'change-both');
    expect(find.text('counter:1'), findsOneWidget);
    expect(find.text('label:changed'), findsOneWidget);
    expect(buildCounts.counter, 2);
    expect(buildCounts.label, 2);
  });

  testWidgets('async commands are awaited and errors propagate', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      AnyScope(
        states: (_) => [const _CounterState(0), const _LabelState('initial')],
        child: MaterialApp(
          home: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await context.call(const _AsyncChangeCounter());
    await tester.pump();
    expect(context.of<_CounterState>().value, 1);
    await expectLater(
      context.call(const _ThrowCommand()),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      context.call(const _ReadMissingState()),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      context.call(const _ReadMissingRepository()),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('CommandContext and mementos save, merge, and restore states', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      AnyScope(
        states: (_) => [0, 'initial'],
        child: MaterialApp(
          home: Builder(
            builder: (buildContext) {
              context = buildContext;
              return Column(
                children: [
                  Text('counter:${buildContext.of<int>()}'),
                  Text('label:${buildContext.of<String>()}'),
                ],
              );
            },
          ),
        ),
      ),
    );

    final allStates = context.save();
    await context.call(const _ExerciseCommandMementos());
    await context.call(const _IncrementInt());
    await tester.pumpAndSettle();

    final counterOnly = context.saveOnly<int>();
    final merged = allStates.merge(counterOnly);
    expect(merged.read<int>(), 1);
    expect(merged.read<String>(), 'initial');
    expect(counterOnly.has<String>(), isFalse);
    expect(() => counterOnly.read<String>(), throwsA(isA<StateError>()));
    expect(find.text('counter:1'), findsOneWidget);
    expect(find.text('label:selected:1'), findsOneWidget);
  });

  testWidgets('BuildContext scope APIs fail clearly without an AnyScope', (
    tester,
  ) async {
    late ScopeMemento memento;
    await tester.pumpWidget(
      AnyScope(
        states: (_) => [const _CounterState(0)],
        child: Builder(
          builder: (context) {
            memento = context.save();
            return const SizedBox();
          },
        ),
      ),
    );

    late BuildContext outsideScope;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          outsideScope = context;
          return const SizedBox();
        },
      ),
    );

    expect(
      () => outsideScope.of<_CounterState>(),
      throwsA(isA<FlutterError>()),
    );
    expect(() => outsideScope.save(), throwsA(isA<FlutterError>()));
    expect(
      () => outsideScope.saveOnly<_CounterState>(),
      throwsA(isA<FlutterError>()),
    );
    expect(() => outsideScope.restore(memento), throwsA(isA<FlutterError>()));
    expect(
      () => outsideScope.call(const _AsyncChangeCounter()),
      throwsA(isA<FlutterError>()),
    );
  });

  testWidgets('restoring an unregistered state is rejected', (tester) async {
    late ScopeMemento memento;
    await tester.pumpWidget(
      AnyScope(
        states: (_) => [const _CounterState(0)],
        child: Builder(
          builder: (context) {
            memento = context.save();
            return const SizedBox();
          },
        ),
      ),
    );

    late BuildContext context;
    await tester.pumpWidget(
      AnyScope(
        key: const ValueKey('different-scope'),
        states: (_) => [const _LabelState('initial')],
        child: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(() => context.restore(memento), throwsA(isA<StateError>()));
  });
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

class _CounterRepository {
  const _CounterRepository(this.initialCount);

  final int initialCount;
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

class _CounterDisplay extends StatelessWidget {
  const _CounterDisplay();

  @override
  Widget build(BuildContext context) =>
      Text('counter:${context.of<_CounterState>().value}');
}

class _CorePage extends StatelessWidget {
  const _CorePage({
    required this.buildCounts,
    required this.onReadRepository,
  });

  final _BuildCounts buildCounts;
  final ValueChanged<BuildContext> onReadRepository;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _CounterView(buildCounts: buildCounts),
      _LabelView(buildCounts: buildCounts),
      ElevatedButton(
        key: const ValueKey('keep-counter'),
        onPressed: () => context.call(const _KeepCounter()),
        child: const Text('Keep counter'),
      ),
      ElevatedButton(
        key: const ValueKey('change-both'),
        onPressed: () => context.call(const _ChangeBoth()),
        child: const Text('Change both'),
      ),
      ElevatedButton(
        key: const ValueKey('read-repository'),
        onPressed: () => onReadRepository(context),
        child: const Text('Read repository'),
      ),
    ],
  );
}

class _CounterView extends StatelessWidget {
  const _CounterView({required this.buildCounts});

  final _BuildCounts buildCounts;

  @override
  Widget build(BuildContext context) {
    buildCounts.counter++;
    return Text('counter:${context.of<_CounterState>().value}');
  }
}

class _LabelView extends StatelessWidget {
  const _LabelView({required this.buildCounts});

  final _BuildCounts buildCounts;

  @override
  Widget build(BuildContext context) {
    buildCounts.label++;
    return Text('label:${context.of<_LabelState>().value}');
  }
}

class _KeepCounter extends Command {
  const _KeepCounter();

  @override
  void call(CommandContext context) {
    final state = context.of<_CounterState>();
    context.call<_CounterState>((_) => state);
  }
}

class _ChangeBoth extends Command {
  const _ChangeBoth();

  @override
  Future<void> call(CommandContext context) async {
    await Future<void>.value();
    context.call<_CounterState>(
      (state) => _CounterState(state.value + 1),
    );
    context.call<_LabelState>((_) => const _LabelState('changed'));
  }
}

class _AsyncChangeCounter extends Command {
  const _AsyncChangeCounter();

  @override
  Future<void> call(CommandContext context) async {
    await Future<void>.value();
    context.call<_CounterState>((state) => _CounterState(state.value + 1));
  }
}

class _ExerciseCommandMementos extends Command {
  const _ExerciseCommandMementos();

  @override
  void call(CommandContext context) {
    final allStates = context.save();
    context.call<int>((counter) => counter + 1);
    final counterOnly = context.saveOnly<int>();
    context.call<int>((counter) => counter + 1);
    context.call<String>((_) => 'changed');
    context.restore(counterOnly);

    final savedCounter = context.of<int>();
    context.restore(allStates);
    context.call<String>((_) => 'selected:$savedCounter');
  }
}

class _IncrementInt extends Command {
  const _IncrementInt();

  @override
  void call(CommandContext context) {
    context.call<int>((counter) => counter + 1);
  }
}

class _AddRepositoryValue extends Command {
  const _AddRepositoryValue();

  @override
  void call(CommandContext context) {
    final first = context.get<_CounterRepository>();
    final second = context.get<_CounterRepository>();
    context.call<_CounterState>(
      (state) => _CounterState(
        state.value + first.initialCount + (identical(first, second) ? 0 : 1),
      ),
    );
  }
}

class _ThrowCommand extends Command {
  const _ThrowCommand();

  @override
  void call(CommandContext context) => throw ArgumentError('command failed');
}

class _ReadMissingState extends Command {
  const _ReadMissingState();

  @override
  void call(CommandContext context) {
    context.of<double>();
  }
}

class _ReadMissingRepository extends Command {
  const _ReadMissingRepository();

  @override
  void call(CommandContext context) {
    context.get<_CounterRepository>();
  }
}
