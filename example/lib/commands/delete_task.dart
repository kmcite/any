import 'package:any/any.dart';
import 'package:example/models/task.dart';
import 'package:example/repositories/tasks.dart';
import 'package:example/states/application_state.dart';

class DeleteTask extends Command {
  const DeleteTask(this.task);

  final Task task;

  @override
  void call(Ref ref) {
    ref.get<TasksRepository>().remove(task);
    ref.call<ApplicationState>(
      (state) => state.copyWith(
        tasks: state.tasks.where((item) => item.id != task.id).toList(),
      ),
    );
  }
}