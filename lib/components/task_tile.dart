import 'package:flutter/material.dart';
import 'package:todocart/models/task.dart';
import 'package:todocart/utils/utils.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<bool?>? onToggle;
  final bool showCheckbox;

  const TaskTile({
    super.key,
    required this.task,
    required this.onDelete,
    required this.onEdit,
    this.onToggle,
    this.showCheckbox = true,
  });

  @override
  Widget build(BuildContext context) {
    final repeatText = formatRepeatRule(task.repeatRule);
    final dueText = formatDueAt(task.dueAt);
    final colors = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: showCheckbox
            ? Checkbox(value: task.isCompleted, onChanged: onToggle)
            : const Icon(Icons.notifications_active_outlined),
        title: Text(task.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text('When: $dueText')),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    task.repeatRule.isRepeating
                        ? Icons.repeat
                        : Icons.repeat_one_outlined,
                    size: 14,
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(repeatText)),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
