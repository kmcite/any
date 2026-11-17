import 'package:any/any.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
          Binding<_Repository>(_Repository()),
          Binding<_Repository>(_Repository()),
        ],
        child: const SizedBox(),
      ),
    );

    expect(tester.takeException(), isA<ArgumentError>());
  });
}

class _Repository {}
