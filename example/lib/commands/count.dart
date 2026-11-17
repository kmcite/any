import 'dart:async';

import 'package:any/any.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/theme_preference.dart';

class CountCommand extends Command {
  @override
  FutureOr<void> call(CommandContext f) {
    f<int>(
      (count) => f.get<TasksRepository>().increment(count),
    );
  }
}

class ToggleDarkCommand extends Command {
  const ToggleDarkCommand();

  @override
  void call(CommandContext f) {
    f<ThemePreference>(
      (theme) => theme.copyWith(isDark: !theme.isDark),
    );
  }
}