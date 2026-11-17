import 'package:any/any.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CounterRepository {
  const CounterRepository([this.initialCount = 0]);

  final int initialCount;
}

class CounterState {
  const CounterState([this.value = 0]);

  final int value;

  CounterState copyWith({int? value}) => CounterState(value ?? this.value);
}

class LabelState {
  const LabelState([this.value = 'initial']);

  final String value;
}

class MutableFlag {
  MutableFlag([this.isDark = false]);

  bool isDark;
}

class BuildCounts {
  int counter = 0;
  int label = 0;
}

class IncrementCounter extends Command {
  const IncrementCounter([this.by = 1]);

  final int by;

  @override
  void call(Ref ref) {
    ref.call<CounterState>(
      (state) => state.copyWith(value: state.value + by),
    );
  }
}

class KeepCounter extends Command {
  const KeepCounter();

  @override
  void call(Ref ref) {
    final state = ref.of<CounterState>();
    ref.call<CounterState>((_) => state);
  }
}

class ChangeLabel extends Command {
  const ChangeLabel([this.value = 'changed']);

  final String value;

  @override
  void call(Ref ref) {
    ref.call<LabelState>((_) => LabelState(value));
  }
}

class ChangeBoth extends Command {
  const ChangeBoth();

  @override
  Future<void> call(Ref ref) async {
    await Future<void>.value();
    ref.call<CounterState>(
      (state) => state.copyWith(value: state.value + 1),
    );
    ref.call<LabelState>((_) => const LabelState('changed'));
  }
}

class ToggleMutableFlag extends Command {
  const ToggleMutableFlag();

  @override
  void call(Ref ref) {
    ref.call<MutableFlag>((flag) => flag..isDark = !flag.isDark);
  }
}

class AsyncIncrementCounter extends Command {
  const AsyncIncrementCounter();

  @override
  Future<void> call(Ref ref) async {
    await Future<void>.value();
    ref.call<CounterState>(
      (state) => state.copyWith(value: state.value + 1),
    );
  }
}

class ThrowCommand extends Command {
  const ThrowCommand();

  @override
  void call(Ref ref) => throw ArgumentError('command failed');
}

class ReadMissingState extends Command {
  const ReadMissingState();

  @override
  void call(Ref ref) {
    ref.of<double>();
  }
}

class ReadMissingRepository extends Command {
  const ReadMissingRepository();

  @override
  void call(Ref ref) {
    ref.get<CounterRepository>();
  }
}

class AddRepositoryValue extends Command {
  const AddRepositoryValue();

  @override
  void call(Ref ref) {
    final first = ref.get<CounterRepository>();
    final second = ref.get<CounterRepository>();
    ref.call<CounterState>(
      (state) => CounterState(
        state.value + first.initialCount + (identical(first, second) ? 0 : 1),
      ),
    );
  }
}

class UpdateUnregisteredState extends Command {
  const UpdateUnregisteredState();

  @override
  void call(Ref ref) {
    ref.call<double>((value) => value + 1);
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Widget scopeApp({
  required StatesBuilder states,
  List<RepositoryBinding> repositories = const [],
  required Widget child,
}) {
  return AnyScope(
    repositories: repositories,
    states: states,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}
