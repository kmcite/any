import 'package:any/any.dart';
import 'package:example/states/application_state.dart';

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
