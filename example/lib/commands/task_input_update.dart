import 'package:any/any.dart';
import 'package:example/states/application_state.dart';

class TaskInputUpdate extends Command {
  const TaskInputUpdate({this.title, this.description});

  final String? title;
  final String? description;

  @override
  void call(Ref ref) {
    ref.call<ApplicationState>(
      (state) => state.copyWith(
        title: title,
        description: description,
      ),
    );
  }
}