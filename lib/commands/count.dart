import 'dart:async';

import 'package:any/repositories/tasks.dart';
import 'package:any/utils/any.dart';

class CountCommand extends Command {
  @override
  FutureOr<void> call(f) {
    f<int>(
      (count) => f.get<TasksRepository>().increment(count),
    );
  }
}

// ignore: non_constant_identifier_names

class ToggleDarkCommand extends Command {
  @override
  void call(f) {
    f<bool>(
      (isDark) => !isDark,
    );
  }
}
