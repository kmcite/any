import 'package:any/states/application_state.dart';
import 'package:any/utils/any.dart';

class TaskInputUpdate extends Command {
  final String? title;
  final String? description;

  TaskInputUpdate({
    this.title,
    this.description,
  });

  @override
  void call(f) {
    f<ApplicationState>(
      (state) => state.copyWith(
        title: title,
        description: description,
      ),
    );
  }
}
