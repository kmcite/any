import 'package:any/any.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/theme_preference.dart';

class CountCommand extends Command {
  const CountCommand();

  @override
  void call(Ref ref) {
    ref.call<int>(
      (count) => ref.get<TasksRepository>().increment(count),
    );
  }
}

class ToggleDarkCommand extends Command {
  const ToggleDarkCommand();

  @override
  void call(Ref ref) {
    ref.call<ThemePreference>(
      (theme) => theme..dark = !theme.dark,
    );
  }
}