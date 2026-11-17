import 'package:any/utils/any.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoryState', () {
    test('starts with no undo or redo entries', () {
      const history = HistoryState();

      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.past, isEmpty);
      expect(history.future, isEmpty);
    });

    test('extendBurst updates grouping metadata without changing history', () {
      final past = <ScopeMemento>[];
      final future = <ScopeMemento>[];
      final initialTime = DateTime.utc(2026, 1, 1);
      final nextTime = DateTime.utc(2026, 1, 1, 0, 0, 1);
      final history = HistoryState(
        past: past,
        future: future,
        maxEntries: 7,
        lastRecordedAt: initialTime,
        lastGroupKey: 'previous',
      );

      final extended = history.extendBurst(nextTime, 'current');

      expect(identical(extended.past, past), isTrue);
      expect(identical(extended.future, future), isTrue);
      expect(extended.maxEntries, 7);
      expect(extended.lastRecordedAt, nextTime);
      expect(extended.lastGroupKey, 'current');
    });
  });
}
