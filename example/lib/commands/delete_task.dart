import 'package:any/any.dart';
import 'package:example/models/task.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/application_state.dart';

class DeleteTask(
  final Task task,
) extends Command {
  @override
  void call(f) {
    f.get<TasksRepository>().remove(task);

    f.call<ApplicationState>(
      (state) => state.copyWith(
        title: '',
        description: '',
        tasks: state.tasks.where((item) => item.id != task.id).toList(),
      ),
    );
  }
}
