import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todocart/components/add_task_bottom_sheet.dart';
import 'package:todocart/models/task.dart';
import 'package:intl/intl.dart';
import 'package:todocart/provider/tasks_provider.dart';
import 'package:todocart/screens/settings_page.dart';
import 'package:todocart/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _showAddOptions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: colors.scrim.withValues(alpha: 0.35),
      builder: (context) {
        return AddTaskBottomSheet(
          onVoiceTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Voice feature coming soon 🎤"),
                backgroundColor: colors.inverseSurface,
              ),
            );
          },
          onTextTap: () {
            Navigator.pop(context);
            _showAddTaskDialog(context);
          },
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final taskProvider = context.read<TasksProvider>();
    String newTaskTitle = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: TextField(
            autofocus: true,
            onChanged: (value) {
              newTaskTitle = value;
            },
            decoration: const InputDecoration(hintText: 'Task Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTaskTitle.isNotEmpty) {
                  taskProvider.addTask(newTaskTitle);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TasksProvider>();
    List<Task> tasks = taskProvider.tasks;
    String user =
        'Sayan'; // for now as a placeholder, this will contain user snapshot from the cached storage.
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    double progress = tasks.isEmpty ? 0 : completedTasks / tasks.length;
    String greeting = setGreeting();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        title: Text(
          'TodoCart',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$greeting, $user ',
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Progress",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : progress,
                    minHeight: 12,
                  ),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Your Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (tasks.isNotEmpty)
                TextButton(
                  onPressed: () => taskProvider.clearCompletedTasks(),
                  child: const Text('Clear Completed'),
                ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsetsGeometry.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(),
                    iconColor: Colors.red,
                    title: Text(tasks[index].title),
                    subtitle: Text(
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(tasks[index].creationTime),
                    ),
                    leading: Checkbox(
                      value: tasks[index].isCompleted,
                      onChanged: (value) =>
                          taskProvider.toggleTask(tasks[index].id),
                    ),
                    trailing: IconButton(
                      onPressed: () => taskProvider.deleteTask(tasks[index].id),
                      icon: const Icon(Icons.delete),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
