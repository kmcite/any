import 'package:any/models/task.dart';
import 'package:any/repositories/tasks.dart';
import 'package:any/states/application_state.dart';
import 'package:any/utils/any.dart';

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
