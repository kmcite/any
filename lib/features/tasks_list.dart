import 'package:any/states/application_state.dart';
import 'package:any/utils/any.dart';
import 'package:flutter/material.dart';

import '../commands/delete_task.dart';
import '../commands/put_task.dart';
import '../commands/task_input_update.dart';

class TasksList extends StatelessWidget {
  const TasksList({super.key});

  @override
  Widget build(BuildContext context) {
    final applicationState = context.of<ApplicationState>();
    final count = context.of<int>();
    final tasks = applicationState.tasks;
    final colors = Theme.of(context).colorScheme;

    Future<void> addTask() async {
      final title = applicationState.title.trim();
      if (title.isEmpty) return;

      await context.call(
        PutTask(
          DateTime.now().toIso8601String(),
          title,
          applicationState.description.trim(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: colors.onSecondaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick actions',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: colors.onSecondaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Tasks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: ValueKey('task-title-${tasks.length}'),
                    initialValue: applicationState.title,
                    onChanged: (value) {
                      context.call(
                        TaskInputUpdate(title: value),
                      );
                    },
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Task title',
                      hintText: 'What needs to get done?',
                      prefixIcon: const Icon(Icons.edit_outlined),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('task-description-${tasks.length}'),
                    initialValue: applicationState.description,
                    onChanged: (value) {
                      context.call(
                        TaskInputUpdate(description: value),
                      );
                    },
                    minLines: 1,
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => addTask(),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Add a few helpful details',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: applicationState.title.trim().isEmpty
                        ? null
                        : addTask,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add task'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.task_alt_rounded,
                              size: 36,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your list is clear',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add a task above to get started.',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline
                                  .withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            key: ValueKey(task.id),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: task.description.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      task.description,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                : null,
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () {
                                context.call(
                                  DeleteTask(task),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
