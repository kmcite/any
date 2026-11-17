import 'dart:async' show StreamController;

import 'package:any/models/task.dart';

class TasksRepository {
  late final tasksController = StreamController<List<Task>>.broadcast()
    ..add(_tasks);
  final List<Task> _tasks = [];

  List<Task> get tasks => List<Task>.of(_tasks);

  Future<void> put(Task task) async {
    _tasks.add(task);
    tasksController.add(_tasks);
  }

  void remove(Task task) {
    _tasks.remove(task);
    tasksController.add(_tasks);
  }

  int increment(int count) => count + 1;
}
