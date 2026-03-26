import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todocart/components/task_tile.dart';
import 'package:todocart/provider/tasks_provider.dart';
import 'package:todocart/screens/edit_task_page.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TasksProvider>();
    final reminders = provider.tasks
        .where((task) => task.dueAt != null || task.repeatRule.isRepeating)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: reminders.isEmpty
          ? const Center(
              child: Text('No reminders yet. Add a task with time/repeat.'),
            )
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final task = reminders[index];

                return TaskTile(
                  task: task,
                  showCheckbox: false,
                  onDelete: () async => provider.deleteTask(task.id),
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTaskPage(task: task),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
