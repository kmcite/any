import 'package:any/states/application_state.dart';
import 'package:any/models/task.dart';
import 'package:any/repositories/tasks.dart';
import 'package:any/utils/any.dart';

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
