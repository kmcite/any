import 'package:any/any.dart';
import 'package:example/commands/count.dart';
import 'package:example/features/custom_bar.dart';
import 'package:example/features/tasks_list.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/application_state.dart';
import 'package:example/states/theme_preference.dart';
import 'package:flutter/material.dart' hide Container;

void main() {
  runApp(
    AnyScope(
      repositories: [
        Binding(TasksRepository()),
      ],
      states: (init) => [
        const ThemePreference(),
        init.get<TasksRepository>().increment(0),
        const ApplicationState(),
        const HistoryState(maxEntries: 50),
      ],
      child: const TasksApp(),
    ),
  );
}

class TasksApp extends StatelessWidget {
  const TasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.of<ThemePreference>().isDark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: CustomBar(
          title: 'My Tasks',
          subtitle: 'Plan your day',
          firstIcon: Icons.brightness_4_rounded,
          onFirstCalled: () {
            context.call(const ToggleDarkCommand());
          },
          secondIcon: Icons.bolt_rounded,
          hasUnreadNotifications: false,
          onSecondCalled: () => context.call(CountCommand()),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: TasksList(),
        ),
      ),
    );
  }
}