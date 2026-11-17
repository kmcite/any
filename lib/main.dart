import 'package:any/commands/count.dart';
import 'package:any/features/custom_bar.dart';
import 'package:any/any.dart';
import 'package:any/states/application_state.dart';
import 'package:any/repositories/tasks.dart';
import 'package:flutter/material.dart' hide Container;

import 'features/tasks_list.dart';

void main() {
  runApp(
    AnyScope(
      repositories: [
        Binding(TasksRepository()),
      ],
      states: (f) => [
        true,
        f.get<TasksRepository>().increment(0),
        ApplicationState(),
      ],
      child: const CounterApp(),
    ),
  );
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: .light(),
      darkTheme: .dark(),
      themeMode: context.of<bool>() ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: CustomBar(
          title: 'My Tasks',
          subtitle: 'Plan your day',
          firstIcon: Icons.brightness_4_rounded,
          onFirstCalled: () {
            context(ToggleDarkCommand());
          },
          secondIcon: Icons.bolt_rounded,
          hasUnreadNotifications: false,
          onSecondCalled: () => context(CountCommand()),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: TasksList(),
        ),
      ),
    );
  }
}
