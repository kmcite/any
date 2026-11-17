import 'package:example/models/task.dart';

class const ApplicationState({
  final String title = '',
  final String description = '',
  final List<Task> tasks = const [],
}) {
  ApplicationState copyWith({
    String? title,
    String? description,
    List<Task>? tasks,
  }) {
    return ApplicationState(
      title: title ?? this.title,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
    );
  }
}
