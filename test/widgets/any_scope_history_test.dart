import 'package:any/utils/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScopeMemento saves, merges, and restores selected states', (
    tester,
  ) async {
    await tester.pumpWidget(_historyApp());

    await _tap(tester, 'inspect-counter-memento');
    expect(find.text('memento:true:false:0'), findsOneWidget);

    await _tap(tester, 'save-all');
    await _tap(tester, 'increment');
    await _tap(tester, 'set-label-captured');
    expect(find.text('counter:1'), findsOneWidget);
    expect(find.text('label:captured'), findsOneWidget);

    await _tap(tester, 'restore-all');
    expect(find.text('counter:0'), findsOneWidget);
    expect(find.text('label:initial'), findsOneWidget);

    await _tap(tester, 'increment');
    await _tap(tester, 'save-counter');
    await _tap(tester, 'set-label-captured');
    await _tap(tester, 'save-label');
    await _tap(tester, 'merge-mementos');
    await _tap(tester, 'increment');
    await _tap(tester, 'set-label-latest');
    await _tap(tester, 'restore-counter');

    expect(find.text('counter:1'), findsOneWidget);
    expect(find.text('label:latest'), findsOneWidget);

    await _tap(tester, 'restore-merged');
    expect(find.text('counter:1'), findsOneWidget);
    expect(find.text('label:captured'), findsOneWidget);
  });

  testWidgets('debounced Record groups updates into one Undo and Redo step', (
    tester,
  ) async {
    await tester.pumpWidget(_historyApp());

    await _tap(tester, 'record');
    expect(find.text('counter:1'), findsOneWidget);
    expect(find.text('history:1:0'), findsOneWidget);

    await _tap(tester, 'record');
    expect(find.text('counter:2'), findsOneWidget);
    expect(find.text('history:1:0'), findsOneWidget);

    await _tap(tester, 'undo');
    expect(find.text('counter:0'), findsOneWidget);
    expect(find.text('history:0:1'), findsOneWidget);

    await _tap(tester, 'redo');
    expect(find.text('counter:2'), findsOneWidget);
    expect(find.text('history:1:0'), findsOneWidget);
  });
}

Widget _historyApp() => AnyScope(
  states: (_) => [0, 'initial', const HistoryState()],
  child: const MaterialApp(
    home: Scaffold(body: _HistoryPage()),
  ),
);

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

class _HistoryPage extends StatefulWidget {
  const _HistoryPage();

  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> {
  ScopeMemento? _allStates;
  ScopeMemento? _counterState;
  ScopeMemento? _labelState;
  ScopeMemento? _mergedStates;
  String? _mementoReadout;

  @override
  Widget build(BuildContext context) {
    final counter = context.of<int>();
    final label = context.of<String>();
    final history = context.of<HistoryState>();

    return SingleChildScrollView(
      child: Column(
        children: [
          Text('counter:$counter'),
          Text('label:$label'),
          Text('history:${history.past.length}:${history.future.length}'),
          if (_mementoReadout != null) Text('memento:$_mementoReadout'),
          ElevatedButton(
            key: const ValueKey('inspect-counter-memento'),
            onPressed: () {
              final memento = context.saveOnly<int>();
              setState(
                () => _mementoReadout =
                    '${memento.has<int>()}:'
                    '${memento.has<String>()}:'
                    '${memento.read<int>()}',
              );
            },
            child: const Text('Inspect counter memento'),
          ),
          ElevatedButton(
            key: const ValueKey('save-all'),
            onPressed: () => setState(() => _allStates = context.save()),
            child: const Text('Save all'),
          ),
          ElevatedButton(
            key: const ValueKey('restore-all'),
            onPressed: () {
              final memento = _allStates;
              if (memento != null) context.restore(memento);
            },
            child: const Text('Restore all'),
          ),
          ElevatedButton(
            key: const ValueKey('increment'),
            onPressed: () async => context.call(const _IncrementCounter()),
            child: const Text('Increment'),
          ),
          ElevatedButton(
            key: const ValueKey('set-label-captured'),
            onPressed: () async => context.call(const _SetLabel('captured')),
            child: const Text('Set captured label'),
          ),
          ElevatedButton(
            key: const ValueKey('set-label-latest'),
            onPressed: () async => context.call(const _SetLabel('latest')),
            child: const Text('Set latest label'),
          ),
          ElevatedButton(
            key: const ValueKey('save-counter'),
            onPressed: () => setState(
              () => _counterState = context.saveOnly<int>(),
            ),
            child: const Text('Save counter'),
          ),
          ElevatedButton(
            key: const ValueKey('save-label'),
            onPressed: () => setState(
              () => _labelState = context.saveOnly<String>(),
            ),
            child: const Text('Save label'),
          ),
          ElevatedButton(
            key: const ValueKey('merge-mementos'),
            onPressed: () {
              final counter = _counterState;
              final label = _labelState;
              if (counter != null && label != null) {
                setState(() => _mergedStates = counter.merge(label));
              }
            },
            child: const Text('Merge mementos'),
          ),
          ElevatedButton(
            key: const ValueKey('restore-counter'),
            onPressed: () {
              final memento = _counterState;
              if (memento != null) context.restore(memento);
            },
            child: const Text('Restore counter'),
          ),
          ElevatedButton(
            key: const ValueKey('restore-merged'),
            onPressed: () {
              final memento = _mergedStates;
              if (memento != null) context.restore(memento);
            },
            child: const Text('Restore merged'),
          ),
          ElevatedButton(
            key: const ValueKey('record'),
            onPressed: () async {
              await context.call(
                const Record<int>(
                  _IncrementCounter(),
                  debounce: Duration(days: 1),
                  groupKey: 'counter',
                ),
              );
            },
            child: const Text('Record'),
          ),
          ElevatedButton(
            key: const ValueKey('undo'),
            onPressed: () async => context.call(const Undo<int>()),
            child: const Text('Undo'),
          ),
          ElevatedButton(
            key: const ValueKey('redo'),
            onPressed: () async => context.call(const Redo<int>()),
            child: const Text('Redo'),
          ),
        ],
      ),
    );
  }
}

class _IncrementCounter extends Command {
  const _IncrementCounter();

  @override
  void call(CommandContext context) {
    context.call<int>((counter) => counter + 1);
  }
}

class _SetLabel extends Command {
  const _SetLabel(this.value);

  final String value;

  @override
  void call(CommandContext context) {
    context.call<String>((_) => value);
  }
}
