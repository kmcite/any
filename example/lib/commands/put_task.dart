import 'package:any/any.dart';
import 'package:example/models/task.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/application_state.dart';

class const PutTask(
  final String id,
  final String title,
  final String description,
) extends Command {
  @override
  Future<void> call(f) async {
    final task = Task(
      id: id,
      title: title,
      description: description,
    );
    await f.get<TasksRepository>().put(task);

    f<ApplicationState>(
      (state) => state.copyWith(
        title: '',
        description: '',
        tasks: [...state.tasks, task],
      ),
    );
  }
}
