import 'package:any/any.dart';
import 'package:example/models/task.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/application_state.dart';

class PutTask extends Command {
  const PutTask();

  @override
  Future<void> call(Ref ref) async {
    final draft = ref.of<ApplicationState>();
    final title = draft.title.trim();
    if (title.isEmpty) return;

    final task = Task(
      id: DateTime.now().toIso8601String(),
      title: title,
      description: draft.description.trim(),
    );

    await ref.get<TasksRepository>().put(task);
    ref.call<ApplicationState>(
      (state) => state.copyWith(
        title: '',
        description: '',
        tasks: [...state.tasks, task],
      ),
    );
  }
}