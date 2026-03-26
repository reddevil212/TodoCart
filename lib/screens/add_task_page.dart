import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todocart/provider/tasks_provider.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await context.read<TasksProvider>().addTask(text);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, 'Task added successfully.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText:
                    'Type your task. Example: remind me to drink water at 10:30 pm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveTask,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_task),
                label: Text(_saving ? 'Adding...' : 'Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
